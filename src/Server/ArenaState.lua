local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeamsService = game:GetService("Teams")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local remotes = Remotes.GetAll()

local ArenaState = {
    MatchState = "Waiting",
    StateEndsAt = 0,
    Players = {},
    Teams = {},
    TeamObjects = {},
    MatchPlayers = {},
    CoreInstances = {},
    ShopInstances = {},
    SpectatorSpawn = nil,
}

local function getNow()
    return os.time()
end

local function shallowCopyArray(values)
    local copied = {}
    for index, value in ipairs(values) do
        copied[index] = value
    end
    return copied
end

local function ensurePlayerState(player)
    local state = ArenaState.Players[player]
    if state then
        return state
    end

    state = {
        TeamId = nil,
        Resources = {
            Iron = 0,
            Gold = 0,
            Emerald = 0,
        },
        Eliminated = false,
        Spectating = true,
        InMatch = false,
    }
    ArenaState.Players[player] = state
    return state
end

local function getTeamById(teamId)
    return ArenaState.Teams[teamId]
end

local function findTeamConfig(teamId)
    for _, teamConfig in ipairs(Config.Teams) do
        if teamConfig.Id == teamId then
            return teamConfig
        end
    end
    return nil
end

function ArenaState.Initialize()
    for _, teamConfig in ipairs(Config.Teams) do
        ArenaState.Teams[teamConfig.Id] = {
            Id = teamConfig.Id,
            DisplayName = teamConfig.DisplayName,
            BiomeDisplayName = teamConfig.BiomeDisplayName,
            Color = teamConfig.Color,
            Members = {},
            AlivePlayers = 0,
            CoreAlive = true,
            CoreHealth = Config.Match.MaxCoreHealth,
            UpgradeLevels = {
                sharpness = 0,
                protection = 0,
                forge = 1,
            },
        }

        local teamObject = TeamsService:FindFirstChild(teamConfig.DisplayName)
        if not teamObject then
            teamObject = Instance.new("Team")
            teamObject.Name = teamConfig.DisplayName
            teamObject.TeamColor = BrickColor.new(teamConfig.Color)
            teamObject.AutoAssignable = false
            teamObject.Parent = TeamsService
        end

        ArenaState.TeamObjects[teamConfig.Id] = teamObject
    end
end

function ArenaState.ResetRoundState()
    ArenaState.MatchPlayers = {}

    for _, teamConfig in ipairs(Config.Teams) do
        local team = getTeamById(teamConfig.Id)
        team.Members = {}
        team.AlivePlayers = 0
        team.CoreAlive = true
        team.CoreHealth = Config.Match.MaxCoreHealth
        team.UpgradeLevels.sharpness = 0
        team.UpgradeLevels.protection = 0
        team.UpgradeLevels.forge = 1
    end

    for player, state in pairs(ArenaState.Players) do
        state.TeamId = nil
        state.Resources.Iron = 0
        state.Resources.Gold = 0
        state.Resources.Emerald = 0
        state.Eliminated = false
        state.Spectating = true
        state.InMatch = false
        if player.Parent then
            player.Team = nil
            player:SetAttribute("TeamId", "")
            player:SetAttribute("CoreAlive", false)
            player:SetAttribute("Eliminated", false)
            player:SetAttribute("InMatch", false)
        end
    end
end

function ArenaState.SetMatchState(nextState, seconds)
    ArenaState.MatchState = nextState
    ArenaState.StateEndsAt = getNow() + (seconds or 0)
    ArenaState.BroadcastMatchState()
end

function ArenaState.BroadcastMatchState()
    remotes.MatchStateUpdated:FireAllClients({
        MatchState = ArenaState.MatchState,
        StateEndsAt = ArenaState.StateEndsAt,
        QueueCount = ArenaState.GetEligiblePlayerCount(),
    })
end

function ArenaState.GetEligiblePlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        players[#players + 1] = player
    end
    table.sort(players, function(left, right)
        return left.UserId < right.UserId
    end)
    return players
end

function ArenaState.GetEligiblePlayerCount()
    return #ArenaState.GetEligiblePlayers()
end

function ArenaState.AssignPlayersToTeams(players)
    ArenaState.MatchPlayers = shallowCopyArray(players)

    for index, player in ipairs(players) do
        local teamConfig = Config.Teams[((index - 1) % #Config.Teams) + 1]
        local team = getTeamById(teamConfig.Id)
        local playerState = ensurePlayerState(player)

        playerState.TeamId = teamConfig.Id
        playerState.Resources.Iron = 0
        playerState.Resources.Gold = 0
        playerState.Resources.Emerald = 0
        playerState.Eliminated = false
        playerState.Spectating = false
        playerState.InMatch = true

        team.Members[#team.Members + 1] = player
        team.AlivePlayers += 1

        player.Team = ArenaState.TeamObjects[teamConfig.Id]
        player:SetAttribute("TeamId", teamConfig.Id)
        player:SetAttribute("CoreAlive", true)
        player:SetAttribute("Eliminated", false)
        player:SetAttribute("InMatch", true)
    end

    ArenaState.BroadcastAllTeamState()
    for _, player in ipairs(players) do
        ArenaState.BroadcastInventory(player)
    end
end

function ArenaState.GetPlayerState(player)
    return ensurePlayerState(player)
end

function ArenaState.GetPlayerTeam(player)
    local state = ensurePlayerState(player)
    if not state.TeamId then
        return nil
    end
    return getTeamById(state.TeamId)
end

function ArenaState.GetPlayerTeamConfig(player)
    local state = ensurePlayerState(player)
    if not state.TeamId then
        return nil
    end
    return findTeamConfig(state.TeamId)
end

function ArenaState.GetTeamConfig(teamId)
    return findTeamConfig(teamId)
end

function ArenaState.AddResource(player, resourceType, amount)
    local state = ensurePlayerState(player)
    state.Resources[resourceType] = math.max(0, (state.Resources[resourceType] or 0) + amount)
    ArenaState.BroadcastInventory(player)
end

function ArenaState.CanAfford(player, resourceType, cost)
    local state = ensurePlayerState(player)
    return (state.Resources[resourceType] or 0) >= cost
end

function ArenaState.SpendResource(player, resourceType, cost)
    local state = ensurePlayerState(player)
    if (state.Resources[resourceType] or 0) < cost then
        return false
    end

    state.Resources[resourceType] -= cost
    ArenaState.BroadcastInventory(player)
    return true
end

function ArenaState.GetTeamStandings()
    local standings = {}
    for _, teamConfig in ipairs(Config.Teams) do
        local team = getTeamById(teamConfig.Id)
        standings[#standings + 1] = {
            TeamId = team.Id,
            DisplayName = team.DisplayName,
            BiomeDisplayName = team.BiomeDisplayName,
            AlivePlayers = team.AlivePlayers,
            CoreAlive = team.CoreAlive,
            CoreHealth = team.CoreHealth,
            Color = team.Color,
        }
    end
    return standings
end

function ArenaState.BroadcastTeamState(player)
    local payload = {
        MatchState = ArenaState.MatchState,
        OwnTeamId = nil,
        Standings = ArenaState.GetTeamStandings(),
    }

    if player then
        local team = ArenaState.GetPlayerTeam(player)
        local state = ensurePlayerState(player)
        payload.OwnTeamId = state.TeamId
        payload.OwnCoreAlive = team and team.CoreAlive or false
        payload.OwnCoreHealth = team and team.CoreHealth or 0
        payload.OwnUpgrades = team and {
            sharpness = team.UpgradeLevels.sharpness,
            protection = team.UpgradeLevels.protection,
            forge = team.UpgradeLevels.forge,
        } or nil
        remotes.TeamStateUpdated:FireClient(player, payload)
        return
    end

    for _, matchPlayer in ipairs(ArenaState.MatchPlayers) do
        ArenaState.BroadcastTeamState(matchPlayer)
    end
end

function ArenaState.BroadcastAllTeamState()
    ArenaState.BroadcastTeamState(nil)
end

function ArenaState.BroadcastInventory(player)
    local state = ensurePlayerState(player)
    remotes.InventoryUpdated:FireClient(player, {
        Resources = {
            Iron = state.Resources.Iron,
            Gold = state.Resources.Gold,
            Emerald = state.Resources.Emerald,
        },
        TeamId = state.TeamId,
        Eliminated = state.Eliminated,
        InMatch = state.InMatch,
    })
end

function ArenaState.PushAnnouncement(message, colorName)
    remotes.AnnouncementPushed:FireAllClients({
        Message = message,
        ColorName = colorName or "Accent",
    })
end

function ArenaState.RegisterCore(teamId, corePart)
    ArenaState.CoreInstances[teamId] = corePart
end

function ArenaState.RegisterShop(teamId, kind, part)
    ArenaState.ShopInstances[teamId] = ArenaState.ShopInstances[teamId] or {}
    ArenaState.ShopInstances[teamId][kind] = part
end

function ArenaState.RegisterSpectatorSpawn(part)
    ArenaState.SpectatorSpawn = part
end

function ArenaState.GetForgeMultiplier(teamId)
    local team = getTeamById(teamId)
    local tier = math.clamp(team and team.UpgradeLevels.forge or 1, 1, #Config.Generators.ForgeIntervals)
    return Config.Generators.ForgeIntervals[tier]
end

function ArenaState.IsEnemy(player, otherPlayer)
    local leftState = ensurePlayerState(player)
    local rightState = ensurePlayerState(otherPlayer)
    return leftState.TeamId ~= nil and rightState.TeamId ~= nil and leftState.TeamId ~= rightState.TeamId
end

function ArenaState.GetUpgradeLevel(teamId, upgradeId)
    local team = getTeamById(teamId)
    if not team then
        return 0
    end
    return team.UpgradeLevels[upgradeId] or 0
end

function ArenaState.AdvanceUpgrade(teamId, upgradeId)
    local team = getTeamById(teamId)
    if not team then
        return nil
    end
    team.UpgradeLevels[upgradeId] = (team.UpgradeLevels[upgradeId] or 0) + 1
    ArenaState.BroadcastAllTeamState()
    return team.UpgradeLevels[upgradeId]
end

function ArenaState.DamageCore(teamId, amount)
    local team = getTeamById(teamId)
    if not team or not team.CoreAlive then
        return false, 0
    end

    team.CoreHealth = math.max(0, team.CoreHealth - amount)
    local corePart = ArenaState.CoreInstances[teamId]
    if corePart then
        corePart:SetAttribute("CoreHealth", team.CoreHealth)
    end

    if team.CoreHealth <= 0 then
        team.CoreAlive = false
        if corePart then
            corePart.Color = Color3.fromRGB(75, 75, 75)
            local prompt = corePart:FindFirstChild("CoreStatus")
            if prompt and prompt:IsA("BillboardGui") then
                local label = prompt:FindFirstChild("Label")
                if label and label:IsA("TextLabel") then
                    label.Text = "Nucleo destruido"
                end
            end
        end
    end

    ArenaState.BroadcastAllTeamState()
    return true, team.CoreHealth
end

function ArenaState.MarkPlayerDead(player)
    local state = ensurePlayerState(player)
    if state.Eliminated then
        return
    end

    local team = ArenaState.GetPlayerTeam(player)
    if team and team.AlivePlayers > 0 then
        team.AlivePlayers -= 1
    end
    ArenaState.BroadcastAllTeamState()
end

function ArenaState.MarkPlayerAlive(player)
    local state = ensurePlayerState(player)
    if state.Eliminated then
        return
    end

    local team = ArenaState.GetPlayerTeam(player)
    if team then
        local count = 0
        for _, teammate in ipairs(team.Members) do
            local teammateState = ArenaState.Players[teammate]
            if teammateState and teammateState.InMatch and not teammateState.Eliminated then
                count += 1
            end
        end
        team.AlivePlayers = count
    end
    ArenaState.BroadcastAllTeamState()
end

function ArenaState.EliminatePlayer(player)
    local state = ensurePlayerState(player)
    state.Eliminated = true
    state.Spectating = true
    player:SetAttribute("Eliminated", true)
    ArenaState.BroadcastInventory(player)
    ArenaState.BroadcastAllTeamState()
end

function ArenaState.IsCoreAlive(teamId)
    local team = getTeamById(teamId)
    return team and team.CoreAlive or false
end

function ArenaState.GetRemainingTeams()
    local aliveTeams = {}
    for _, teamConfig in ipairs(Config.Teams) do
        local team = getTeamById(teamConfig.Id)
        local survivors = 0
        for _, player in ipairs(team.Members) do
            local state = ArenaState.Players[player]
            if state and state.InMatch and not state.Eliminated then
                survivors += 1
            end
        end
        team.AlivePlayers = survivors
        if survivors > 0 then
            aliveTeams[#aliveTeams + 1] = team
        end
    end
    return aliveTeams
end

function ArenaState.RecordKill(attackerUserId, victimPlayer)
    if not attackerUserId or attackerUserId == 0 then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == attackerUserId then
            local leaderstats = player:FindFirstChild("leaderstats")
            local kills = leaderstats and leaderstats:FindFirstChild("Kills")
            local finalKills = leaderstats and leaderstats:FindFirstChild("FinalKills")
            if kills then
                kills.Value += 1
            end

            local victimState = ensurePlayerState(victimPlayer)
            if victimState.TeamId and not ArenaState.IsCoreAlive(victimState.TeamId) and finalKills then
                finalKills.Value += 1
            end
            break
        end
    end
end

function ArenaState.RecordWin(teamId)
    local team = getTeamById(teamId)
    if not team then
        return
    end

    for _, player in ipairs(team.Members) do
        local leaderstats = player:FindFirstChild("leaderstats")
        local wins = leaderstats and leaderstats:FindFirstChild("Wins")
        if wins then
            wins.Value += 1
        end
    end
end

function ArenaState.RecordCoreBreak(attackerPlayer)
    if not attackerPlayer then
        return
    end

    local leaderstats = attackerPlayer:FindFirstChild("leaderstats")
    local broken = leaderstats and leaderstats:FindFirstChild("CoresBroken")
    if broken then
        broken.Value += 1
    end
end

function ArenaState.GetShopPart(player, kind)
    local state = ensurePlayerState(player)
    local shops = state.TeamId and ArenaState.ShopInstances[state.TeamId]
    return shops and shops[kind] or nil
end

function ArenaState.TeleportPlayerToBase(player)
    local teamConfig = ArenaState.GetPlayerTeamConfig(player)
    if not teamConfig or not player.Character then
        return
    end
    player.Character:PivotTo(CFrame.new(teamConfig.BasePosition + Vector3.new(0, 5, 18)))
end

function ArenaState.TeleportPlayerToSpectator(player)
    if not ArenaState.SpectatorSpawn or not player.Character then
        return
    end
    player.Character:PivotTo(ArenaState.SpectatorSpawn.CFrame + Vector3.new(0, 4, 0))
end

return ArenaState
