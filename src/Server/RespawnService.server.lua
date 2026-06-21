local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local remotes = Remotes.GetAll()

local function onHumanoidDied(player, humanoid)
    local playerState = ArenaState.GetPlayerState(player)
    if not playerState.InMatch then
        return
    end

    ArenaState.MarkPlayerDead(player)
    ArenaState.ClearPlayerLoadout(player)
    local attackerUserId = humanoid:GetAttribute("LastAttackerUserId")
    local attackAt = humanoid:GetAttribute("LastAttackAt") or 0
    if attackerUserId and (os.clock() - attackAt) <= Config.Combat.KillCreditWindowSeconds then
        ArenaState.RecordKill(attackerUserId, player)
    end

    if playerState.TeamId and ArenaState.IsCoreAlive(playerState.TeamId) then
        remotes.RespawnStateUpdated:FireClient(player, {
            RespawnIn = Config.Match.RespawnSeconds,
            Spectating = false,
        })
        task.delay(Config.Match.RespawnSeconds, function()
            if player.Parent and playerState.TeamId and ArenaState.IsCoreAlive(playerState.TeamId) then
                ArenaState.ApplyRespawnLocation(player)
                player:LoadCharacter()
            end
        end)
    else
        ArenaState.EliminatePlayer(player)
        remotes.RespawnStateUpdated:FireClient(player, {
            RespawnIn = 0,
            Spectating = true,
        })
        task.delay(2, function()
            if player.Parent then
                ArenaState.ApplyRespawnLocation(player)
                player:LoadCharacter()
            end
        end)
    end
end

local function setupCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local playerState = ArenaState.GetPlayerState(player)

    humanoid.Health = humanoid.MaxHealth
    humanoid.Died:Connect(function()
        onHumanoidDied(player, humanoid)
    end)

    if playerState.Spectating then
        task.defer(function()
            ArenaState.ApplyRespawnLocation(player)
            ArenaState.TeleportPlayerToSpectator(player)
        end)
        rootPart.CanCollide = true
    elseif playerState.InLobby then
        task.defer(function()
            ArenaState.ApplyRespawnLocation(player)
            ArenaState.TeleportPlayerToLobby(player)
            ArenaState.BroadcastMatchState()
            ArenaState.BroadcastTeamState(player)
        end)
    elseif playerState.InMatch then
        task.defer(function()
            ArenaState.ApplyRespawnLocation(player)
            ArenaState.TeleportPlayerToBase(player)
            ArenaState.MarkPlayerAlive(player)
            ArenaState.BroadcastMatchState()
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    ArenaState.ApplyRespawnLocation(player)
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    ArenaState.ApplyRespawnLocation(player)
    if player.Character then
        task.spawn(setupCharacter, player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
end

Workspace:WaitForChild("CSFanZone")
