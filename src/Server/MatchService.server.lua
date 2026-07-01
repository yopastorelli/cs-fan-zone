local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local function updateCoreStatusVisual(corePart, text)
    local status = corePart:FindFirstChild("CoreStatus")
    local label = status and status:FindFirstChild("Label")
    if label and label:IsA("TextLabel") then
        label.Text = text
    end

    local plinth = corePart.Parent and corePart.Parent:FindFirstChild("CoreStatusPlinth")
    if plinth then
        for _, child in ipairs(plinth:GetChildren()) do
            if child:IsA("SurfaceGui") then
                local surfaceLabel = child:FindFirstChild("TextLabel")
                if surfaceLabel and surfaceLabel:IsA("TextLabel") then
                    surfaceLabel.Text = text
                end
            end
        end
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
            local parent = descendant.Parent
            local totemFlag = parent and parent:FindFirstChild("TotemFlag")
            if totemFlag and totemFlag:IsA("BasePart") and team then
                totemFlag.Color = (VisualKit.Biomes[team.Id] and VisualKit.Biomes[team.Id].Secondary) or team.Color
            end
            local crest = parent and parent:FindFirstChild("TotemCrest")
            if crest and crest:IsA("BasePart") and team then
                crest.Color = (VisualKit.Biomes[team.Id] and VisualKit.Biomes[team.Id].Accent) or team.Color:Lerp(Color3.new(1, 1, 1), 0.12)
            end
            updateCoreStatusVisual(descendant, string.format("Totem %d/%d", Config.Match.MaxCoreHealth, Config.Match.MaxCoreHealth))
        end
    end
end

local function clearInventories()
    for _, player in ipairs(Players:GetPlayers()) do
        ArenaState.ClearPlayerLoadout(player)
    end
end

local function beginRound(players)
    local roundToken = ArenaState.AdvanceRoundToken()
    clearRoundDebris()
    clearInventories()
    ArenaState.ResetRoundState()
    local assignedPlayers = ArenaState.AssignPlayersToTeams(players)
    ArenaState.SetMatchResult("Reset", nil)
    ArenaState.SetMatchState("Active", Config.Match.SuddenDeathSeconds)
    local roundFormat = ArenaState.GetCurrentRoundFormat()
    local formatDisplay = ArenaState.GetRoundFormatDisplay(roundFormat)
    ArenaState.PushAnnouncement(string.format("Rodada %s iniciada. Ao nascer: pegue ferro, abra a loja e prepare a ponte para o Meio.", formatDisplay), "Accent")

    for _, player in ipairs(assignedPlayers) do
        ArenaState.ApplyRespawnLocation(player)
        player:LoadCharacter()
    end

    for _, player in ipairs(players) do
        local assigned = false
        for _, selectedPlayer in ipairs(assignedPlayers) do
            if selectedPlayer == player then
                assigned = true
                break
            end
        end
        if not assigned then
            ArenaState.PushFeedback(player, "InfoMessage", {
                Message = Config.UI.Messages.OverflowLobby,
            })
        end
    end

    task.delay(Config.Match.SuddenDeathSeconds, function()
        if ArenaState.GetRoundToken() ~= roundToken or ArenaState.MatchState ~= "Active" then
            return
        end

        ArenaState.SetMatchState("SuddenDeath", Config.Match.PostMatchSeconds)
        for teamId in pairs(ArenaState.Teams) do
            if ArenaState.IsTeamActive(teamId) then
                ArenaState.DamageCore(teamId, Config.Match.MaxCoreHealth)
            end
        end
        ArenaState.PushAnnouncement("Morte Subita. Os totens ativos foram destruidos.", "Danger")
    end)
end

local function returnEveryoneToLobby()
    ArenaState.AdvanceRoundToken()
    ArenaState.ResetRoundState()
    clearRoundDebris()
    clearInventories()
    for _, player in ipairs(Players:GetPlayers()) do
        ArenaState.ApplyRespawnLocation(player)
        player:LoadCharacter()
    end
end

local function matchLoop()
    while true do
        task.wait(1)

        if ArenaState.MatchState == "Waiting" then
            local eligible = ArenaState.GetEligiblePlayers()
            ArenaState.SetProjectedActiveTeams(#eligible)
            if #eligible >= Config.Match.MinPlayersToStart then
                ArenaState.SetMatchResult("Reset", nil)
                ArenaState.SetMatchState("Starting", Config.Match.CountdownSeconds)
                ArenaState.PushAnnouncement("Contagem iniciada para a proxima rodada.", "Warning")
            else
                ArenaState.BroadcastMatchState()
            end
        elseif ArenaState.MatchState == "Starting" then
            local eligible = ArenaState.GetEligiblePlayers()
            ArenaState.SetProjectedActiveTeams(#eligible)
            local secondsLeft = ArenaState.StateEndsAt - os.time()
            if #eligible < Config.Match.MinPlayersToStart then
                ArenaState.SetMatchResult("Reset", nil)
                ArenaState.SetMatchState("Waiting", 0)
                ArenaState.PushAnnouncement("Contagem cancelada. Faltam jogadores.", "Warning")
            elseif secondsLeft <= 0 then
                beginRound(eligible)
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
