local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local function updateCoreStatusVisual(corePart, text)
    local status = corePart:FindFirstChild("CoreStatus")
    local label = status and status:FindFirstChild("Label")
    if label and label:IsA("TextLabel") then
        label.Text = text
    end

    local plinth = corePart.Parent and corePart.Parent:FindFirstChild("CoreStatusPlinth")
    local surfaceGui = plinth and plinth:FindFirstChild("SurfaceGui")
    local surfaceLabel = surfaceGui and surfaceGui:FindFirstChild("TextLabel")
    if surfaceLabel and surfaceLabel:IsA("TextLabel") then
        surfaceLabel.Text = text
    end
end

local function clearRoundDebris()
    local world = Workspace:WaitForChild("CSFanZone")
    local generatorDrops = world:FindFirstChild("GeneratorDrops")
    if generatorDrops then
        generatorDrops:ClearAllChildren()
    end

    for _, descendant in ipairs(world:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("PlacedBlock") == true then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") and descendant.Name == "Core" then
            local teamId = descendant:GetAttribute("CoreTeamId")
            local team = ArenaState.Teams[teamId]
            descendant.Color = team and team.Color or Color3.fromRGB(255, 255, 255)
            descendant:SetAttribute("CoreHealth", Config.Match.MaxCoreHealth)
            updateCoreStatusVisual(descendant, string.format("Nucleo %d/%d", Config.Match.MaxCoreHealth, Config.Match.MaxCoreHealth))
        end
    end
end

local function clearInventories()
    for _, player in ipairs(Players:GetPlayers()) do
        ArenaState.ClearPlayerLoadout(player)
    end
end

local function beginRound(players)
    clearRoundDebris()
    clearInventories()
    ArenaState.ResetRoundState()
    ArenaState.AssignPlayersToTeams(players)
    ArenaState.SetMatchResult("Reset", nil)
    ArenaState.SetMatchState("Active", Config.Match.SuddenDeathSeconds)
    ArenaState.PushAnnouncement("Rodada iniciada. Protejam o nucleo e avancem pelo centro.", "Accent")

    for _, player in ipairs(players) do
        player:LoadCharacter()
    end

    task.delay(Config.Match.SuddenDeathSeconds, function()
        if ArenaState.MatchState ~= "Active" then
            return
        end

        ArenaState.SetMatchState("SuddenDeath", Config.Match.PostMatchSeconds)
        for teamId in pairs(ArenaState.Teams) do
            ArenaState.DamageCore(teamId, Config.Match.MaxCoreHealth)
        end
        ArenaState.PushAnnouncement("Morte Subita. Todos os nucleos foram destruidos.", "Danger")
    end)
end

local function returnEveryoneToLobby()
    ArenaState.ResetRoundState()
    clearRoundDebris()
    clearInventories()
    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end
end

local function matchLoop()
    while true do
        task.wait(1)

        if ArenaState.MatchState == "Waiting" then
            local eligible = ArenaState.GetEligiblePlayers()
            if #eligible >= Config.Match.MinPlayersToStart then
                ArenaState.SetMatchResult("Reset", nil)
                ArenaState.SetMatchState("Starting", Config.Match.CountdownSeconds)
                ArenaState.PushAnnouncement("Contagem iniciada para a proxima rodada.", "Warning")
            else
                ArenaState.BroadcastMatchState()
            end
        elseif ArenaState.MatchState == "Starting" then
            local eligible = ArenaState.GetEligiblePlayers()
            local secondsLeft = ArenaState.StateEndsAt - os.time()
            if #eligible < Config.Match.MinPlayersToStart then
                ArenaState.SetMatchResult("Reset", nil)
                ArenaState.SetMatchState("Waiting", 0)
                ArenaState.PushAnnouncement("Contagem cancelada. Faltam jogadores.", "Warning")
            elseif secondsLeft <= 0 then
                local selected = {}
                for index, player in ipairs(eligible) do
                    if index > Config.Match.MaxPlayers then
                        break
                    end
                    selected[#selected + 1] = player
                end
                beginRound(selected)
            else
                ArenaState.BroadcastMatchState()
            end
        elseif ArenaState.MatchState == "Ended" then
            local secondsLeft = ArenaState.StateEndsAt - os.time()
            if secondsLeft <= 0 then
                ArenaState.SetMatchResult("Reset", nil)
                ArenaState.SetMatchState("Waiting", 0)
                returnEveryoneToLobby()
            else
                ArenaState.BroadcastMatchState()
            end
        else
            ArenaState.BroadcastMatchState()
        end
    end
end

ArenaState.Initialize()
ArenaState.SetMatchResult("Reset", nil)
ArenaState.SetMatchState("Waiting", 0)
task.spawn(matchLoop)
