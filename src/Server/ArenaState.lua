local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeamsService = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))
local TelemetryService = require(script.Parent:WaitForChild("TelemetryService"))

local remotes = Remotes.GetAll()

local ArenaState = {
    MatchState = "Waiting",
    StateEndsAt = 0,
    MatchEndReason = "Reset",
    WinningTeamId = nil,
    RoundToken = 0,
    Players = {},
    Teams = {},
    TeamObjects = {},
    MatchPlayers = {},
    ActiveTeamIds = {},
    CoreInstances = {},
    ShopInstances = {},
    TeamSpawns = {},
    LobbySpawn = nil,
    SpectatorSpawn = nil,
    NextQueueTicket = 0,
    CurrentRoundFormat = nil,
    LastMatchPayloadKeys = {},
    LastTeamPayloadKeys = {},
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

local function joinArray(values)
    if type(values) ~= "table" then
        return ""
    end
    return table.concat(values, "|")
end

local function createGuidedProgress()
    return {
        CollectedIron = false,
        OpenedShop = false,
        BoughtStarterBlocks = false,
        BoughtStarterSword = false,
        BoughtStarterPickaxe = false,
        BuiltFirstBridge = false,
        ReachedMiddleIsland = false,
        CollectedEmerald = false,
    }
end

local function getWorld()
    return Workspace:FindFirstChild("CSFanZone")
end

local function assignQueueTicket(state)
    ArenaState.NextQueueTicket += 1
    state.QueueTicket = ArenaState.NextQueueTicket
end

local function getLobbySpawn()
    if ArenaState.LobbySpawn and ArenaState.LobbySpawn.Parent then
        return ArenaState.LobbySpawn
    end
    local world = getWorld()
    local lobby = world and world:FindFirstChild("Lobby")
    local spawn = lobby and lobby:FindFirstChild("LobbySpawn")
    if spawn then
        ArenaState.LobbySpawn = spawn
    end
    return spawn
end

local function ensurePlayerState(player)
    local state = ArenaState.Players[player]
    if state then
        if not state.QueueTicket or state.QueueTicket <= 0 then
            assignQueueTicket(state)
        end
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
        Spectating = false,
        InMatch = false,
        InLobby = true,
        LastLoadoutResetAt = 0,
        SpawnProtectedUntil = 0,
        GuidedProgress = createGuidedProgress(),
        QueueTicket = 0,
    }
    assignQueueTicket(state)
    ArenaState.Players[player] = state
    return state
end

local function movePlayerToBackOfQueue(player)
    local state = ensurePlayerState(player)
    assignQueueTicket(state)
end

local function getTeamById(teamId)
    return ArenaState.Teams[teamId]
end

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

local function findTeamConfig(teamId)
    for _, teamConfig in ipairs(Config.Teams) do
        if teamConfig.Id == teamId then
            return teamConfig
        end
    end
    return nil
end

local function getShopItemById(itemId)
    for _, item in ipairs(Config.Shop.Items) do
        if item.Id == itemId then
            return item
        end
    end
    return nil
end

local function getStarterItemCost(itemId)
    local item = getShopItemById(itemId)
    if not item then
        return nil, nil
    end
    return item.ResourceType, item.Cost
end

local function getHelpText(player)
    local phase = ArenaState.GetPlayerPhase(player)
    if phase == "Lobby" then
        if ArenaState.MatchState == "Active" or ArenaState.MatchState == "SuddenDeath" or ArenaState.MatchState == "Ended" then
            return Config.UI.Hints.LateJoin
        end
        if ArenaState.GetEligiblePlayerCount() < Config.Match.MinPlayersToStart then
            return Config.UI.KidHelpMessages.Lobby
        end
        return Config.UI.HelpMessagesByState[ArenaState.MatchState] or Config.UI.HelpMessagesByState.Lobby
    end
    if phase == "Spectating" then
        return Config.UI.KidHelpMessages.Spectating
    end
    return Config.UI.HelpMessagesByState[ArenaState.MatchState] or ""
end

local function getRecommendedStarter(player)
    local state = ensurePlayerState(player)
    if ArenaState.GetPlayerPhase(player) ~= "InMatch" then
        return nil, ""
    end

    local progress = state.GuidedProgress
    local isDuos = (ArenaState.CurrentRoundFormat and ArenaState.CurrentRoundFormat.Mode) == "Duos"
    if not progress.BoughtStarterBlocks then
        return Config.UI.StarterFlow.First, isDuos
            and "Compre blocos e abra a saida do time."
            or "Compre blocos para fazer sua primeira ponte."
    end
    if not progress.BuiltFirstBridge then
        return nil, isDuos
            and "Use os blocos e abra a ponte do time ate o Meio."
            or "Use os blocos para fechar sua primeira ponte ate o Meio."
    end
    if not progress.CollectedEmerald then
        return nil, "Agora avance ate o Meio e pegue sua primeira esmeralda."
    end
    if not progress.BoughtStarterSword then
        return Config.UI.StarterFlow.Second, isDuos
            and "Com espada voce segura a primeira troca do time."
            or "Com espada voce segura melhor a primeira troca."
    end
    if not progress.BoughtStarterPickaxe then
        return Config.UI.StarterFlow.Third, isDuos
            and "Agora pegue picareta para pressionar o totem rival."
            or "Agora pegue picareta para pressionar o totem inimigo."
    end
    return nil, ""
end

local function getStarterAffordability(player)
    local itemId = getRecommendedStarter(player)
    if not itemId then
        return nil, false
    end
    local resourceType, cost = getStarterItemCost(itemId)
    return itemId, resourceType and ArenaState.CanAfford(player, resourceType, cost) or false
end

local function getGuidedStepState(player)
    local state = ensurePlayerState(player)
    local steps = Config.UI.GuidedSteps
    if ArenaState.GetPlayerPhase(player) ~= "InMatch" then
        return 0, nil, nil, nil
    end

    local progress = state.GuidedProgress
    local currentStep = 6

    if not progress.CollectedIron then
        currentStep = 1
    elseif not progress.OpenedShop then
        currentStep = 2
    elseif not progress.BoughtStarterBlocks then
        currentStep = 3
    elseif not progress.BuiltFirstBridge then
        currentStep = 4
    elseif not progress.CollectedEmerald then
        currentStep = 5
    end

    local stepConfig = steps[currentStep]
    return currentStep, stepConfig and stepConfig.Title, stepConfig and stepConfig.Hint, stepConfig and stepConfig.Target
end

local function resolveRoundFormatForPlayers(playerCount)
    local matchConfig = Config.Match
    local formats = matchConfig.Formats or {}
    local soloConfig = formats.Solo1v1 or {}
    local duosConfig = formats.Duos or {}
    local duoThreshold = duosConfig.MinPlayers or 4

    if playerCount < duoThreshold then
        local teamCount = soloConfig.TeamCount or matchConfig.MinTeamsToStart
        local playersPerTeam = soloConfig.PlayersPerTeam or 1
        return {
            Mode = soloConfig.Mode or "Solo1v1",
            TeamCount = teamCount,
            PlayersPerTeam = playersPerTeam,
            PlayerLimit = soloConfig.PlayerLimit or (teamCount * playersPerTeam),
            DisplayName = soloConfig.DisplayName or "1v1",
        }
    end

    local playersPerTeam = math.max(duosConfig.PlayersPerTeam or matchConfig.PlayersPerTeam or 2, 1)
    local availablePlayers = math.min(playerCount, duosConfig.MaxPlayers or matchConfig.MaxPlayers, matchConfig.MaxPlayers)
    local minTeams = duosConfig.MinTeams or matchConfig.MinTeamsToStart
    local maxTeams = duosConfig.MaxTeams or matchConfig.SupportedTeamCounts[#matchConfig.SupportedTeamCounts] or #Config.Teams
    local teamCount = math.clamp(math.floor(availablePlayers / playersPerTeam), minTeams, maxTeams)

    return {
        Mode = duosConfig.Mode or "Duos",
        TeamCount = teamCount,
        PlayersPerTeam = playersPerTeam,
        PlayerLimit = teamCount * playersPerTeam,
        DisplayNameSingular = duosConfig.DisplayNameSingular or "dupla",
        DisplayNamePlural = duosConfig.DisplayNamePlural or "duplas",
    }
end

local function getProjectedTeamCount(playerCount)
    if playerCount <= 0 then
        return Config.Match.MinTeamsToStart
    end
    return resolveRoundFormatForPlayers(playerCount).TeamCount
end

local function getProjectedRoundFormat(playerCount)
    return resolveRoundFormatForPlayers(playerCount)
end

local function isTeamActive(teamId)
    return ArenaState.ActiveTeamIds[teamId] == true
end

local function setSurfaceText(part, text)
    local surfaceGui = part and part:FindFirstChild("SurfaceGui")
    local label = surfaceGui and surfaceGui:FindFirstChild("TextLabel")
    if label and label:IsA("TextLabel") then
        label.Text = text
    end
end

local function setAllSurfaceText(part, text)
    if not part then
        return
    end
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("SurfaceGui") then
            local label = child:FindFirstChild("TextLabel")
            if label and label:IsA("TextLabel") then
                label.Text = text
            end
        end
    end
end

local function updateBaseVisualState(teamId, active)
    local world = getWorld()
    local baseFolder = world and world:FindFirstChild(teamId)
    local teamConfig = findTeamConfig(teamId)
    if not baseFolder or not teamConfig then
        return
    end

    baseFolder:SetAttribute("ActiveInRound", active)

    for _, descendant in ipairs(baseFolder:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant:GetAttribute("OriginalTransparency") == nil then
                descendant:SetAttribute("OriginalTransparency", descendant.Transparency)
            end
            local originalTransparency = descendant:GetAttribute("OriginalTransparency") or 0
            if active then
                descendant.Transparency = originalTransparency
            else
                descendant.Transparency = math.clamp(originalTransparency + 0.45, 0, 0.82)
            end
        elseif descendant:IsA("ProximityPrompt") then
            descendant.Enabled = active
        end
    end

    local banner = baseFolder:FindFirstChild("BiomeBanner")
    if banner and banner:IsA("BasePart") then
        setSurfaceText(banner, active and teamConfig.BiomeDisplayName or (teamConfig.BiomeDisplayName .. "\nReserva"))
    end
end

local function getRoundFormatDisplay(roundFormat)
    local format = roundFormat or resolveRoundFormatForPlayers(0)
    if format.Mode == "Duos" then
        local label = format.TeamCount == 1 and format.DisplayNameSingular or format.DisplayNamePlural
        return string.format("%d %s", format.TeamCount, label or "duplas")
    end
    return format.DisplayName or "1v1"
end

local function getRoundFormatLabel(roundFormat, inMatch)
    local template = inMatch and Config.UI.AdaptiveQueueText.Active or Config.UI.AdaptiveQueueText.Format
    return string.format(template, getRoundFormatDisplay(roundFormat))
end

local function updateLobbyWorldState(queueCount, projectedRoundFormat, playersNeededForNextRecommendedFormat, resolvedRoundState)
    local world = getWorld()
    local lobby = world and world:FindFirstChild("Lobby")
    if not lobby then
        return
    end

    local queueSign = lobby:FindFirstChild("QueueStatusSign")
    local tacticalBoard = lobby:FindFirstChild("TacticalBoard")
    local mapBoard = lobby:FindFirstChild("MiniMapBoard")

    local queueLines = {
        Config.UI.MatchStateLabels[ArenaState.MatchState] or ArenaState.MatchState,
        string.format(Config.UI.AdaptiveQueueText.Current, queueCount),
    }
    if ArenaState.MatchState == "Active" or ArenaState.MatchState == "SuddenDeath" or ArenaState.MatchState == "Ended" then
        queueLines[#queueLines + 1] = string.format(Config.UI.AdaptiveQueueText.Active, getRoundFormatDisplay(ArenaState.CurrentRoundFormat or projectedRoundFormat))
    else
        queueLines[#queueLines + 1] = string.format(Config.UI.AdaptiveQueueText.Format, getRoundFormatDisplay(projectedRoundFormat))
        if playersNeededForNextRecommendedFormat > 0 then
            queueLines[#queueLines + 1] = string.format(Config.UI.AdaptiveQueueText.Next, playersNeededForNextRecommendedFormat)
        else
            queueLines[#queueLines + 1] = "Pronto para iniciar"
        end
    end

    local tacticalText
    if resolvedRoundState then
        tacticalText = "Mapa rapido\nLate join fica no lobby\nBase -> Ilha do Meio -> Centro"
    elseif queueCount < Config.Match.MinPlayersToStart then
        tacticalText = "Mapa rapido\nEspere mais jogadores\nBase -> Ilha do Meio -> Centro"
    elseif ArenaState.MatchState == "Starting" then
        tacticalText = "Mapa rapido\nContagem em andamento\nVoce vai para uma base"
    else
        tacticalText = "Mapa rapido\nRodada pronta\nBase -> Ilha do Meio -> Centro"
    end

    setAllSurfaceText(queueSign, table.concat(queueLines, "\n"))
    setAllSurfaceText(tacticalBoard, tacticalText)
    setAllSurfaceText(mapBoard, string.format("Mini mapa da rodada\n%s\nConstrua para sair da base", getRoundFormatLabel(projectedRoundFormat, resolvedRoundState)))
end

local function getObjectiveText(player)
    local phase = ArenaState.GetPlayerPhase(player)
    if phase == "InMatch" then
        return Config.UI.Onboarding.ByPhase.Active or Config.UI.Onboarding.Objectives
    elseif phase == "Spectating" then
        return Config.UI.Onboarding.ByPhase.Spectating or Config.UI.Onboarding.Objectives
    elseif ArenaState.MatchState == "Starting" then
        return Config.UI.Onboarding.ByPhase.Starting or Config.UI.Onboarding.Objectives
    end
    return Config.UI.Onboarding.ByPhase.Lobby or Config.UI.Onboarding.Objectives
end

local function buildMatchPayload(player, queueCount, projectedRoundFormat, inResolvedRoundState, playersNeededForNextRecommendedFormat)
    local phase = ArenaState.GetPlayerPhase(player)
    local currentStep, objectiveTitle, objectiveHint, objectiveTarget = getGuidedStepState(player)
    return {
        MatchState = ArenaState.MatchState,
        StateEndsAt = ArenaState.StateEndsAt,
        RemainingSeconds = math.max(0, ArenaState.StateEndsAt - getNow()),
        QueueCount = queueCount,
        MinPlayersToStart = Config.Match.MinPlayersToStart,
        PlayerPhase = phase,
        ObjectiveText = getObjectiveText(player),
        HelpText = getHelpText(player),
        WinningTeamId = ArenaState.WinningTeamId,
        RoundToken = ArenaState.RoundToken,
        EndReason = ArenaState.MatchEndReason,
        ActiveTeamCount = ArenaState.GetActiveTeamCount(),
        QueuedPlayers = queueCount,
        PlayersNeededForNextRecommendedFormat = playersNeededForNextRecommendedFormat,
        RoundFormatLabel = getRoundFormatLabel(projectedRoundFormat, inResolvedRoundState or phase == "InMatch" or phase == "Spectating"),
        RoundMode = projectedRoundFormat.Mode,
        PlayersPerTeam = projectedRoundFormat.PlayersPerTeam,
        CurrentObjectiveStep = currentStep,
        ObjectiveTitle = objectiveTitle,
        ObjectiveHint = objectiveHint,
        ObjectiveTarget = objectiveTarget,
    }
end

local function makeMatchPayloadKey(payload)
    return table.concat({
        payload.MatchState or "",
        tostring(payload.StateEndsAt or 0),
        tostring(payload.RemainingSeconds or 0),
        tostring(payload.QueueCount or 0),
        tostring(payload.PlayerPhase or ""),
        joinArray(payload.ObjectiveText),
        tostring(payload.HelpText or ""),
        tostring(payload.WinningTeamId or ""),
        tostring(payload.RoundToken or 0),
        tostring(payload.EndReason or ""),
        tostring(payload.ActiveTeamCount or 0),
        tostring(payload.PlayersNeededForNextRecommendedFormat or 0),
        tostring(payload.RoundFormatLabel or ""),
        tostring(payload.RoundMode or ""),
        tostring(payload.PlayersPerTeam or 0),
        tostring(payload.CurrentObjectiveStep or 0),
        tostring(payload.ObjectiveTitle or ""),
        tostring(payload.ObjectiveHint or ""),
        tostring(payload.ObjectiveTarget or ""),
    }, "||")
end

local function makeStandingsKey(standings)
    local parts = {}
    for _, standing in ipairs(standings or {}) do
        parts[#parts + 1] = table.concat({
            standing.TeamId or "",
            tostring(standing.AlivePlayers or 0),
            tostring(standing.CoreAlive == true),
            tostring(standing.CoreHealth or 0),
        }, ":")
    end
    return table.concat(parts, "|")
end

local function makeTeamPayloadKey(payload)
    return table.concat({
        tostring(payload.MatchState or ""),
        tostring(payload.OwnTeamId or ""),
        tostring(payload.OwnCoreAlive == true),
        tostring(payload.OwnCoreHealth or 0),
        tostring(payload.PlayerPhase or ""),
        tostring(payload.CurrentObjectiveStep or 0),
        tostring(payload.ObjectiveTitle or ""),
        tostring(payload.ObjectiveHint or ""),
        tostring(payload.ObjectiveTarget or ""),
        tostring(payload.TotemDisplayState or ""),
        tostring(payload.HasStarterWeapon == true),
        tostring(payload.HasPickaxe == true),
        tostring(payload.CanAffordStarterBlock == true),
        tostring(payload.CanAffordStarterSword == true),
        tostring(payload.CoreExposedWarning == true),
        joinArray(payload.OwnLoadoutHints),
        tostring(payload.RecommendedStarterItemId or ""),
        tostring(payload.RecommendedStarterReason or ""),
        tostring(payload.HasBuiltFirstBridge == true),
        tostring(payload.ReachedMiddleIsland == true),
        tostring(payload.OwnUpgrades and payload.OwnUpgrades.sharpness or 0),
        tostring(payload.OwnUpgrades and payload.OwnUpgrades.protection or 0),
        tostring(payload.OwnUpgrades and payload.OwnUpgrades.forge or 0),
        makeStandingsKey(payload.Standings),
    }, "||")
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

function ArenaState.GetPlayerPhase(player)
    local state = ensurePlayerState(player)
    if state.Spectating then
        return "Spectating"
    end
    if state.InMatch then
        return "InMatch"
    end
    return "Lobby"
end

function ArenaState.IsPlayerInLobby(player)
    return ArenaState.GetPlayerPhase(player) == "Lobby"
end

function ArenaState.IsPlayerInMatch(player)
    return ArenaState.GetPlayerPhase(player) == "InMatch"
end

function ArenaState.IsPlayerSpectating(player)
    return ArenaState.GetPlayerPhase(player) == "Spectating"
end

function ArenaState.ResetRoundState()
    ArenaState.MatchPlayers = {}
    ArenaState.ActiveTeamIds = {}
    ArenaState.WinningTeamId = nil
    ArenaState.MatchEndReason = "Reset"
    ArenaState.CurrentRoundFormat = nil

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
        state.Spectating = false
        state.InMatch = false
        state.InLobby = true
        state.SpawnProtectedUntil = 0
        state.GuidedProgress = createGuidedProgress()
        if player.Parent then
            player.Team = nil
            player.RespawnLocation = getLobbySpawn()
            player:SetAttribute("TeamId", "")
            player:SetAttribute("CoreAlive", false)
            player:SetAttribute("Eliminated", false)
            player:SetAttribute("InMatch", false)
            player:SetAttribute("PlayerPhase", "Lobby")
        end
        ArenaState.LastMatchPayloadKeys[player] = nil
        ArenaState.LastTeamPayloadKeys[player] = nil
    end

    ArenaState.SetProjectedActiveTeams(ArenaState.GetEligiblePlayerCount())
end

function ArenaState.AdvanceRoundToken()
    ArenaState.RoundToken += 1
    return ArenaState.RoundToken
end

function ArenaState.GetRoundToken()
    return ArenaState.RoundToken
end

function ArenaState.SetMatchState(nextState, seconds, extra)
    ArenaState.MatchState = nextState
    ArenaState.StateEndsAt = getNow() + (seconds or 0)
    ArenaState.MatchEndReason = extra and extra.EndReason or ArenaState.MatchEndReason
    ArenaState.WinningTeamId = extra and extra.WinningTeamId or ArenaState.WinningTeamId
    ArenaState.BroadcastMatchState()
end

function ArenaState.SetMatchResult(endReason, winningTeamId)
    ArenaState.MatchEndReason = endReason or "Reset"
    ArenaState.WinningTeamId = winningTeamId
end

function ArenaState.GetEligiblePlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local state = ensurePlayerState(player)
        if not state.InMatch and not state.Spectating then
            players[#players + 1] = player
        end
    end
    table.sort(players, function(left, right)
        local leftState = ensurePlayerState(left)
        local rightState = ensurePlayerState(right)
        if leftState.QueueTicket ~= rightState.QueueTicket then
            return leftState.QueueTicket < rightState.QueueTicket
        end
        return left.UserId < right.UserId
    end)
    return players
end

function ArenaState.GetEligiblePlayerCount()
    return #ArenaState.GetEligiblePlayers()
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

function ArenaState.GetTeamStandings()
    local standings = {}
    for _, teamConfig in ipairs(Config.Teams) do
        local team = getTeamById(teamConfig.Id)
        if isTeamActive(team.Id) then
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
    end
    return standings
end

function ArenaState.GetWinningTeam()
    return ArenaState.WinningTeamId and getTeamById(ArenaState.WinningTeamId) or nil
end

function ArenaState.BroadcastMatchState()
    local queueCount = ArenaState.GetEligiblePlayerCount()
    local inResolvedRoundState = ArenaState.MatchState == "Active"
        or ArenaState.MatchState == "SuddenDeath"
        or ArenaState.MatchState == "Ended"
    local projectedRoundFormat = inResolvedRoundState
        and (ArenaState.CurrentRoundFormat or getProjectedRoundFormat(queueCount))
        or getProjectedRoundFormat(queueCount)
    local playersNeededForNextRecommendedFormat
    if queueCount < Config.Match.MinPlayersToStart then
        playersNeededForNextRecommendedFormat = math.max(0, Config.Match.MinPlayersToStart - queueCount)
    else
        playersNeededForNextRecommendedFormat = 0
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local payload = buildMatchPayload(player, queueCount, projectedRoundFormat, inResolvedRoundState, playersNeededForNextRecommendedFormat)
        local payloadKey = makeMatchPayloadKey(payload)
        if ArenaState.LastMatchPayloadKeys[player] ~= payloadKey then
            ArenaState.LastMatchPayloadKeys[player] = payloadKey
            remotes.MatchStateUpdated:FireClient(player, payload)
        end
    end

    updateLobbyWorldState(queueCount, projectedRoundFormat, playersNeededForNextRecommendedFormat, inResolvedRoundState)
end

function ArenaState.BroadcastTeamState(player)
    local payload = {
        MatchState = ArenaState.MatchState,
        OwnTeamId = nil,
        Standings = {},
    }

    if player then
        local team = ArenaState.GetPlayerTeam(player)
        local state = ensurePlayerState(player)
        local phase = ArenaState.GetPlayerPhase(player)
        local currentStep, objectiveTitle, objectiveHint, objectiveTarget = getGuidedStepState(player)
        local recommendedStarterItemId, recommendedStarterReason = getRecommendedStarter(player)
        payload.OwnTeamId = state.TeamId
        payload.OwnCoreAlive = team and team.CoreAlive or false
        payload.OwnCoreHealth = team and team.CoreHealth or 0
        payload.PlayerPhase = phase
        payload.CurrentObjectiveStep = currentStep
        payload.ObjectiveTitle = objectiveTitle
        payload.ObjectiveHint = objectiveHint
        payload.ObjectiveTarget = objectiveTarget
        payload.OwnUpgrades = team and {
            sharpness = team.UpgradeLevels.sharpness,
            protection = team.UpgradeLevels.protection,
            forge = team.UpgradeLevels.forge,
        } or nil
        payload.TotemDisplayState = team and (team.CoreAlive and "Ativo" or "Destruido") or "Sem time"
        payload.HasStarterWeapon = ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.SwordItemId)
        payload.HasPickaxe = ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.PickaxeItemId)
        do
            local blockResource, blockCost = getStarterItemCost(Config.UI.StarterRecommendations.BlockItemId)
            local swordResource, swordCost = getStarterItemCost(Config.UI.StarterRecommendations.SwordItemId)
            payload.CanAffordStarterBlock = blockResource and ArenaState.CanAfford(player, blockResource, blockCost) or false
            payload.CanAffordStarterSword = swordResource and ArenaState.CanAfford(player, swordResource, swordCost) or false
        end
        payload.CoreExposedWarning = payload.OwnCoreAlive and not payload.HasPickaxe and not payload.HasStarterWeapon
        payload.OwnLoadoutHints = ArenaState.GetLoadoutHints(player)
        payload.RecommendedStarterItemId = recommendedStarterItemId
        payload.RecommendedStarterReason = recommendedStarterReason
        payload.HasBuiltFirstBridge = state.GuidedProgress.BuiltFirstBridge
        payload.ReachedMiddleIsland = state.GuidedProgress.ReachedMiddleIsland
        if phase ~= "Lobby" then
            payload.Standings = ArenaState.GetTeamStandings()
        end
        local payloadKey = makeTeamPayloadKey(payload)
        if ArenaState.LastTeamPayloadKeys[player] ~= payloadKey then
            ArenaState.LastTeamPayloadKeys[player] = payloadKey
            remotes.TeamStateUpdated:FireClient(player, payload)
        end
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

function ArenaState.SetSpawnProtection(player)
    local state = ensurePlayerState(player)
    local expiresAt = os.clock() + Config.Combat.SpawnProtectionSeconds
    state.SpawnProtectedUntil = expiresAt
    if player and player.Parent then
        player:SetAttribute("SpawnProtectedUntil", expiresAt)
    end
    return expiresAt
end

function ArenaState.IsSpawnProtected(player)
    local state = ensurePlayerState(player)
    return (state.SpawnProtectedUntil or 0) > os.clock()
end

function ArenaState.PushAnnouncement(message, colorName)
    remotes.AnnouncementPushed:FireAllClients({
        Message = message,
        ColorName = colorName or "Accent",
    })
end

function ArenaState.PushFeedback(player, feedbackType, payload)
    local body = payload or {}
    body.Type = feedbackType
    if player then
        remotes.FeedbackPushed:FireClient(player, body)
    else
        remotes.FeedbackPushed:FireAllClients(body)
    end
end

function ArenaState.AssignPlayersToTeams(players)
    local roundFormat = resolveRoundFormatForPlayers(#players)
    local activeTeamCount = roundFormat.TeamCount
    local selectedPlayers = {}
    local selectedTeams = {}
    local playerLimit = math.min(Config.Match.MaxPlayers, roundFormat.PlayerLimit)

    ArenaState.MatchPlayers = {}
    ArenaState.ActiveTeamIds = {}
    ArenaState.CurrentRoundFormat = roundFormat

    for index = 1, activeTeamCount do
        local teamConfig = Config.Teams[index]
        selectedTeams[#selectedTeams + 1] = teamConfig
        ArenaState.ActiveTeamIds[teamConfig.Id] = true
    end

    for _, teamConfig in ipairs(Config.Teams) do
        updateBaseVisualState(teamConfig.Id, ArenaState.ActiveTeamIds[teamConfig.Id] == true)
    end

    for index, player in ipairs(players) do
        if index > playerLimit then
            break
        end
        local teamConfig = selectedTeams[((index - 1) % #selectedTeams) + 1]
        local team = getTeamById(teamConfig.Id)
        local playerState = ensurePlayerState(player)

        playerState.TeamId = teamConfig.Id
        playerState.Resources.Iron = 0
        playerState.Resources.Gold = 0
        playerState.Resources.Emerald = 0
        playerState.Eliminated = false
        playerState.Spectating = false
        playerState.InMatch = true
        playerState.InLobby = false
        playerState.SpawnProtectedUntil = 0
        playerState.GuidedProgress = createGuidedProgress()

        team.Members[#team.Members + 1] = player
        team.AlivePlayers += 1

        player.Team = ArenaState.TeamObjects[teamConfig.Id]
        player:SetAttribute("TeamId", teamConfig.Id)
        player:SetAttribute("CoreAlive", true)
        player:SetAttribute("Eliminated", false)
        player:SetAttribute("InMatch", true)
        player:SetAttribute("PlayerPhase", "InMatch")
        ArenaState.ApplyRespawnLocation(player)
        selectedPlayers[#selectedPlayers + 1] = player
        movePlayerToBackOfQueue(player)
    end

    ArenaState.MatchPlayers = shallowCopyArray(selectedPlayers)

    ArenaState.BroadcastAllTeamState()
    for _, player in ipairs(selectedPlayers) do
        ArenaState.BroadcastInventory(player)
    end
    return selectedPlayers
end

function ArenaState.AddResource(player, resourceType, amount)
    if not ArenaState.CanCollectResources(player) then
        return false
    end
    local previousStep = select(1, getGuidedStepState(player))
    local previousRecommendedItemId, previousAffordable = getStarterAffordability(player)
    local state = ensurePlayerState(player)
    state.Resources[resourceType] = math.max(0, (state.Resources[resourceType] or 0) + amount)
    if resourceType == "Iron" then
        state.GuidedProgress.CollectedIron = true
        TelemetryService.TrackOneShot(player, "ftue_collect_iron")
        TelemetryService.TrackFunnelStep(player, 2, "collect_iron", "ftue_collect_iron")
    elseif resourceType == "Emerald" then
        state.GuidedProgress.CollectedEmerald = true
        TelemetryService.TrackOneShot(player, "ftue_collect_emerald")
        TelemetryService.TrackFunnelStep(player, 7, "collect_emerald", "ftue_collect_emerald")
    end
    ArenaState.BroadcastInventory(player)
    local currentStep = select(1, getGuidedStepState(player))
    local currentRecommendedItemId, currentAffordable = getStarterAffordability(player)
    if currentStep ~= previousStep
        or currentRecommendedItemId ~= previousRecommendedItemId
        or currentAffordable ~= previousAffordable
    then
        ArenaState.BroadcastTeamState(player)
    end
    return true
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

function ArenaState.RegisterCore(teamId, corePart)
    ArenaState.CoreInstances[teamId] = corePart
end

function ArenaState.RegisterLobbySpawn(spawnPart)
    ArenaState.LobbySpawn = spawnPart
end

function ArenaState.RegisterTeamSpawn(teamId, spawnPart)
    ArenaState.TeamSpawns[teamId] = spawnPart
end

function ArenaState.RegisterShop(teamId, kind, part)
    ArenaState.ShopInstances[teamId] = ArenaState.ShopInstances[teamId] or {}
    ArenaState.ShopInstances[teamId][kind] = part
end

function ArenaState.RegisterSpectatorSpawn(part)
    ArenaState.SpectatorSpawn = part
end

function ArenaState.ApplyRespawnLocation(player)
    local state = ensurePlayerState(player)
    if state.Spectating then
        player.RespawnLocation = ArenaState.SpectatorSpawn
        return
    end

    if state.InMatch and state.TeamId then
        player.RespawnLocation = ArenaState.TeamSpawns[state.TeamId]
        return
    end

    player.RespawnLocation = getLobbySpawn()
end

function ArenaState.GetForgeMultiplier(teamId)
    local team = getTeamById(teamId)
    local tier = math.clamp(team and team.UpgradeLevels.forge or 1, 1, #Config.Generators.ForgeIntervals)
    return Config.Generators.ForgeIntervals[tier]
end

function ArenaState.GetDamageReduction(teamId)
    local team = getTeamById(teamId)
    if not team then
        return 0
    end
    local level = team.UpgradeLevels.protection or 0
    local protectionConfig = Config.TeamUpgrades.Items[2]
    if protectionConfig and protectionConfig.EffectValues[level] then
        return protectionConfig.EffectValues[level]
    end
    return 0
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

function ArenaState.CanCollectResources(player)
    return ArenaState.IsPlayerInMatch(player)
end

function ArenaState.IsInsideLobbySafeZone(position)
    local lobbyPosition = Config.World.Lobby.SpawnPosition
    local extents = Config.World.Lobby.SafeZoneHalfExtents
    return math.abs(position.X - lobbyPosition.X) <= extents.X
        and math.abs(position.Y - lobbyPosition.Y) <= extents.Y
        and math.abs(position.Z - lobbyPosition.Z) <= extents.Z
end

function ArenaState.IsInsideSpectatorZone(position)
    local center = Config.World.Spectator.DeckPosition
    local half = (Config.World.Spectator.DeckSize / 2) + Vector3.new(4, 10, 4)
    return math.abs(position.X - center.X) <= half.X
        and math.abs(position.Y - center.Y) <= half.Y
        and math.abs(position.Z - center.Z) <= half.Z
end

function ArenaState.IsRestrictedPlacementPosition(player, snappedPosition)
    if ArenaState.IsInsideLobbySafeZone(snappedPosition) or ArenaState.IsInsideSpectatorZone(snappedPosition) then
        return true
    end

    local teamConfig = ArenaState.GetPlayerTeamConfig(player)
    local restrictedRadius = Config.Combat.RestrictedPlacementRadius
    for _, shopByKind in pairs(ArenaState.ShopInstances) do
        for _, shopPart in pairs(shopByKind) do
            if shopPart and shopPart.Parent and (shopPart.Position - snappedPosition).Magnitude <= restrictedRadius then
                return true
            end
        end
    end

    for _, corePart in pairs(ArenaState.CoreInstances) do
        if corePart and corePart.Parent and (corePart.Position - snappedPosition).Magnitude <= restrictedRadius then
            return true
        end
    end

    if teamConfig and (teamConfig.BasePosition + Vector3.new(0, 0, 18) - snappedPosition).Magnitude <= restrictedRadius then
        return true
    end

    return false
end

function ArenaState.CanUseShop(player, shopPart)
    if not player or not shopPart or not shopPart:IsA("BasePart") then
        return false, "Loja invalida"
    end
    if not ArenaState.IsPlayerInMatch(player) then
        return false, "Voce precisa estar em partida"
    end

    local state = ensurePlayerState(player)
    local shopTeamId = shopPart:GetAttribute("TeamId")
    if not isTeamActive(shopTeamId) then
        return false, "Base reserva"
    end
    if state.TeamId ~= shopTeamId then
        return false, "Loja de outro time"
    end

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false, "Personagem indisponivel"
    end

    local shopKind = shopPart:GetAttribute("ShopKind")
    local maxDistance = shopKind == "Upgrades" and Config.Interaction.UpgradeDistance or Config.Interaction.ShopDistance
    if (rootPart.Position - shopPart.Position).Magnitude > maxDistance then
        return false, "Chegue mais perto da loja"
    end

    return true
end

function ArenaState.DamageCore(teamId, amount)
    local team = getTeamById(teamId)
    if not team or not team.CoreAlive then
        return false, 0
    end
    if not isTeamActive(teamId) then
        return false, team.CoreHealth
    end

    team.CoreHealth = math.max(0, team.CoreHealth - amount)
    local corePart = ArenaState.CoreInstances[teamId]
    if corePart then
        corePart:SetAttribute("CoreHealth", team.CoreHealth)
        corePart.Color = team.CoreHealth > 0 and team.Color:Lerp(Color3.new(1, 1, 1), 0.25) or Color3.fromRGB(75, 75, 75)
        local totemFlag = corePart.Parent and corePart.Parent:FindFirstChild("TotemFlag")
        if totemFlag and totemFlag:IsA("BasePart") then
            totemFlag.Color = team.CoreHealth > 0 and (VisualKit.Biomes[team.Id] and VisualKit.Biomes[team.Id].Secondary or team.Color) or Color3.fromRGB(88, 88, 88)
        end
        local crest = corePart.Parent and corePart.Parent:FindFirstChild("TotemCrest")
        if crest and crest:IsA("BasePart") then
            crest.Color = team.CoreHealth > 0 and (VisualKit.Biomes[team.Id] and VisualKit.Biomes[team.Id].Accent or team.Color) or Color3.fromRGB(154, 154, 154)
        end
        updateCoreStatusVisual(
            corePart,
            team.CoreHealth > 0
                and string.format("Totem %d/%d", team.CoreHealth, Config.Match.MaxCoreHealth)
                or "Totem destruido"
        )
    end

    if team.CoreHealth <= 0 then
        team.CoreAlive = false
        for _, member in ipairs(team.Members) do
            if member.Parent then
                member:SetAttribute("CoreAlive", false)
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
    state.InLobby = false
    ArenaState.ApplyRespawnLocation(player)
    player:SetAttribute("Eliminated", true)
    player:SetAttribute("PlayerPhase", "Spectating")
    ArenaState.LastMatchPayloadKeys[player] = nil
    ArenaState.LastTeamPayloadKeys[player] = nil
    ArenaState.BroadcastInventory(player)
    ArenaState.BroadcastMatchState()
    ArenaState.BroadcastAllTeamState()
    TelemetryService.TrackOneShot(player, "match_eliminated")
end

function ArenaState.IsCoreAlive(teamId)
    local team = getTeamById(teamId)
    return team and isTeamActive(teamId) and team.CoreAlive or false
end

function ArenaState.GetRemainingTeams()
    local aliveTeams = {}
    for _, teamConfig in ipairs(Config.Teams) do
        local team = getTeamById(teamConfig.Id)
        local survivors = 0
        if isTeamActive(teamConfig.Id) then
            for _, player in ipairs(team.Members) do
                local state = ArenaState.Players[player]
                if state and state.InMatch and not state.Eliminated then
                    survivors += 1
                end
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
    if not team or not isTeamActive(teamId) then
        return
    end

    for _, player in ipairs(team.Members) do
        local leaderstats = player:FindFirstChild("leaderstats")
        local wins = leaderstats and leaderstats:FindFirstChild("Wins")
        if wins then
            wins.Value += 1
        end
        TelemetryService.TrackOneShot(player, "match_victory")
    end
end

function ArenaState.RecordCoreBreak(attackerPlayer)
    if not attackerPlayer then
        return
    end

    local leaderstats = attackerPlayer:FindFirstChild("leaderstats")
    local broken = leaderstats and leaderstats:FindFirstChild("TotemsBroken")
    if broken then
        broken.Value += 1
    end
end

function ArenaState.GetShopPart(player, kind)
    local state = ensurePlayerState(player)
    local shops = state.TeamId and ArenaState.ShopInstances[state.TeamId]
    return shops and shops[kind] or nil
end

function ArenaState.PlayerHasTool(player, itemId)
    local configById = {}
    for _, item in ipairs(Config.Shop.Items) do
        configById[item.Id] = item
    end
    local itemConfig = configById[itemId]
    if not itemConfig then
        return false
    end

    local displayName = itemConfig.DisplayName
    local backpack = player:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(displayName) then
        return true
    end
    local character = player.Character
    return character and character:FindFirstChild(displayName) ~= nil or false
end

function ArenaState.GetLoadoutHints(player)
    local hints = {}
    local state = ensurePlayerState(player)
    if ArenaState.GetPlayerPhase(player) ~= "InMatch" then
        return hints
    end

    local progress = state.GuidedProgress
    if not progress.CollectedIron then
        hints[#hints + 1] = Config.UI.Hints.NoResources
    elseif not progress.OpenedShop then
        hints[#hints + 1] = Config.UI.Hints.FirstShopOpen
    elseif not progress.BoughtStarterBlocks then
        hints[#hints + 1] = Config.UI.Hints.CanBuyBlocks
    elseif not progress.BuiltFirstBridge then
        hints[#hints + 1] = Config.UI.KidHelpMessages.FirstBridge
    elseif not progress.CollectedEmerald then
        hints[#hints + 1] = Config.UI.Hints.ReachMiddle
    elseif not ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.PickaxeItemId) then
        hints[#hints + 1] = Config.UI.Hints.NeedPickaxe
    else
        local swordResource, swordCost = getStarterItemCost(Config.UI.StarterRecommendations.SwordItemId)
        if swordResource and ArenaState.CanAfford(player, swordResource, swordCost) and not ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.SwordItemId) then
            hints[#hints + 1] = Config.UI.Hints.CanBuySword
        end
    end

    return hints
end

function ArenaState.GetActiveTeamCount()
    local count = 0
    for _, active in pairs(ArenaState.ActiveTeamIds) do
        if active then
            count += 1
        end
    end
    return count
end

function ArenaState.ResolveRoundFormatForPlayers(playerCount)
    return resolveRoundFormatForPlayers(playerCount)
end

function ArenaState.GetRoundFormatDisplay(roundFormat)
    return getRoundFormatDisplay(roundFormat or ArenaState.CurrentRoundFormat or resolveRoundFormatForPlayers(ArenaState.GetEligiblePlayerCount()))
end

function ArenaState.GetCurrentRoundFormat()
    return ArenaState.CurrentRoundFormat or resolveRoundFormatForPlayers(ArenaState.GetEligiblePlayerCount())
end

function ArenaState.MarkShopOpened(player)
    local state = ensurePlayerState(player)
    if not state.GuidedProgress.OpenedShop then
        state.GuidedProgress.OpenedShop = true
        TelemetryService.TrackOneShot(player, "ftue_open_shop")
        TelemetryService.TrackFunnelStep(player, 3, "open_shop", "ftue_open_shop")
        ArenaState.BroadcastTeamState(player)
    end
end

function ArenaState.MarkStarterPurchase(player, itemId)
    local state = ensurePlayerState(player)
    if itemId == Config.UI.StarterFlow.First then
        state.GuidedProgress.BoughtStarterBlocks = true
        TelemetryService.TrackOneShot(player, "ftue_buy_blocks")
        TelemetryService.TrackFunnelStep(player, 4, "buy_blocks", "ftue_buy_blocks")
    elseif itemId == Config.UI.StarterFlow.Second then
        state.GuidedProgress.BoughtStarterSword = true
    elseif itemId == Config.UI.StarterFlow.Third then
        state.GuidedProgress.BoughtStarterPickaxe = true
    end
    ArenaState.BroadcastTeamState(player)
end

function ArenaState.MarkFirstBridgeBuilt(player)
    local state = ensurePlayerState(player)
    if not state.GuidedProgress.BuiltFirstBridge then
        state.GuidedProgress.BuiltFirstBridge = true
        TelemetryService.TrackOneShot(player, "ftue_build_first_bridge")
        TelemetryService.TrackFunnelStep(player, 5, "build_first_bridge", "ftue_build_first_bridge")
        ArenaState.PushFeedback(player, "FirstBridgeBuilt", {
            Message = Config.UI.Hints.FirstBridge,
        })
        ArenaState.BroadcastTeamState(player)
    end
end

function ArenaState.MarkReachedMiddleIsland(player)
    local state = ensurePlayerState(player)
    if not state.GuidedProgress.ReachedMiddleIsland then
        state.GuidedProgress.ReachedMiddleIsland = true
        TelemetryService.TrackOneShot(player, "ftue_reach_middle")
        TelemetryService.TrackFunnelStep(player, 6, "reach_middle", "ftue_reach_middle")
        ArenaState.PushFeedback(player, "FirstMiddleReached", {
            Message = Config.UI.Hints.ReachMiddle,
        })
        ArenaState.BroadcastTeamState(player)
    end
end

function ArenaState.IsTeamActive(teamId)
    return isTeamActive(teamId)
end

function ArenaState.SetProjectedActiveTeams(playerCount)
    local projectedCount = getProjectedTeamCount(playerCount)
    local activeMap = {}
    for index = 1, projectedCount do
        activeMap[Config.Teams[index].Id] = true
    end
    for _, teamConfig in ipairs(Config.Teams) do
        updateBaseVisualState(teamConfig.Id, activeMap[teamConfig.Id] == true)
    end
end

function ArenaState.ClearPlayerLoadout(player)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        backpack:ClearAllChildren()
    end
    local character = player.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                child:Destroy()
            end
        end
    end
    local state = ensurePlayerState(player)
    state.LastLoadoutResetAt = os.clock()
end

function ArenaState.TeleportPlayerToBase(player)
    local teamConfig = ArenaState.GetPlayerTeamConfig(player)
    local spawnPart = teamConfig and ArenaState.TeamSpawns[teamConfig.Id]
    if not teamConfig or not spawnPart or not player.Character then
        return
    end
    player.Character:PivotTo(spawnPart.CFrame + Vector3.new(0, 4, 0))
end

function ArenaState.TeleportPlayerToLobby(player)
    local lobbySpawn = getLobbySpawn()
    if not lobbySpawn or not player.Character then
        return
    end
    player.Character:PivotTo(lobbySpawn.CFrame + Vector3.new(0, 4, 0))
end

function ArenaState.TeleportPlayerToSpectator(player)
    if not ArenaState.SpectatorSpawn or not player.Character then
        return
    end
    player.Character:PivotTo(ArenaState.SpectatorSpawn.CFrame + Vector3.new(0, 4, 0))
end

Players.PlayerRemoving:Connect(function(player)
    ArenaState.LastMatchPayloadKeys[player] = nil
    ArenaState.LastTeamPayloadKeys[player] = nil
    ArenaState.Players[player] = nil
end)

return ArenaState
