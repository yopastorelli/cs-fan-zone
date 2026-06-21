local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeamsService = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local remotes = Remotes.GetAll()

local ArenaState = {
    MatchState = "Waiting",
    StateEndsAt = 0,
    MatchEndReason = "Reset",
    WinningTeamId = nil,
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

local function getWorld()
    return Workspace:FindFirstChild("CSFanZone")
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
    }
    ArenaState.Players[player] = state
    return state
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
    local surfaceGui = plinth and plinth:FindFirstChild("SurfaceGui")
    local surfaceLabel = surfaceGui and surfaceGui:FindFirstChild("TextLabel")
    if surfaceLabel and surfaceLabel:IsA("TextLabel") then
        surfaceLabel.Text = text
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

local function getHelpText(player)
    local phase = ArenaState.GetPlayerPhase(player)
    if phase == "Lobby" then
        if ArenaState.MatchState == "Active" or ArenaState.MatchState == "SuddenDeath" or ArenaState.MatchState == "Ended" then
            return Config.UI.Hints.LateJoin
        end
        return Config.UI.HelpMessagesByState[ArenaState.MatchState] or Config.UI.HelpMessagesByState.Lobby
    end
    if phase == "Spectating" then
        return Config.UI.HelpMessagesByState.Spectating
    end
    return Config.UI.HelpMessagesByState[ArenaState.MatchState] or ""
end

local function getSupportedTeamCountForPlayers(playerCount)
    local supported = Config.Match.SupportedTeamCounts
    local pairCount = math.floor(playerCount / Config.Match.PreferredPlayersPerTeam)
    local selected = supported[1]

    for _, value in ipairs(supported) do
        if pairCount >= value then
            selected = value
        else
            break
        end
    end

    return math.clamp(selected or Config.Match.MinTeamsToStart, Config.Match.MinTeamsToStart, supported[#supported])
end

local function getProjectedTeamCount(playerCount)
    if playerCount <= 0 then
        return Config.Match.MinTeamsToStart
    end
    return getSupportedTeamCountForPlayers(playerCount)
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

local function getRoundFormatLabel(teamCount, inMatch)
    local template = inMatch and Config.UI.AdaptiveQueueText.Active or Config.UI.AdaptiveQueueText.Format
    return string.format(template, teamCount)
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
        if player.Parent then
            player.Team = nil
            player.RespawnLocation = getLobbySpawn()
            player:SetAttribute("TeamId", "")
            player:SetAttribute("CoreAlive", false)
            player:SetAttribute("Eliminated", false)
            player:SetAttribute("InMatch", false)
            player:SetAttribute("PlayerPhase", "Lobby")
        end
    end

    ArenaState.SetProjectedActiveTeams(ArenaState.GetEligiblePlayerCount())
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
    local projectedTeamCount = inResolvedRoundState
        and ArenaState.GetActiveTeamCount()
        or getProjectedTeamCount(queueCount)
    local playersNeededForNextRecommendedFormat
    if queueCount < Config.Match.MinPlayersToStart then
        playersNeededForNextRecommendedFormat = math.max(0, (Config.Match.MinTeamsToStart * Config.Match.PreferredPlayersPerTeam) - queueCount)
    else
        local nextSupportedTeamCount = math.min(Config.Match.SupportedTeamCounts[#Config.Match.SupportedTeamCounts], projectedTeamCount + 1)
        playersNeededForNextRecommendedFormat = math.max(0, (nextSupportedTeamCount * Config.Match.PreferredPlayersPerTeam) - queueCount)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local phase = ArenaState.GetPlayerPhase(player)
        remotes.MatchStateUpdated:FireClient(player, {
            MatchState = ArenaState.MatchState,
            StateEndsAt = ArenaState.StateEndsAt,
            QueueCount = queueCount,
            MinPlayersToStart = Config.Match.MinPlayersToStart,
            PlayerPhase = phase,
            ObjectiveText = getObjectiveText(player),
            HelpText = getHelpText(player),
            WinningTeamId = ArenaState.WinningTeamId,
            EndReason = ArenaState.MatchEndReason,
            ActiveTeamCount = ArenaState.GetActiveTeamCount(),
            QueuedPlayers = queueCount,
            PlayersNeededForNextRecommendedFormat = playersNeededForNextRecommendedFormat,
            RoundFormatLabel = getRoundFormatLabel(projectedTeamCount, phase == "InMatch" or phase == "Spectating"),
        })
    end
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
        payload.OwnTeamId = state.TeamId
        payload.OwnCoreAlive = team and team.CoreAlive or false
        payload.OwnCoreHealth = team and team.CoreHealth or 0
        payload.PlayerPhase = phase
        payload.OwnUpgrades = team and {
            sharpness = team.UpgradeLevels.sharpness,
            protection = team.UpgradeLevels.protection,
            forge = team.UpgradeLevels.forge,
        } or nil
        payload.HasStarterWeapon = ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.SwordItemId)
        payload.HasPickaxe = ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.PickaxeItemId)
        payload.CanAffordStarterBlock = ArenaState.CanAfford(player, "Iron", 16)
        payload.CanAffordStarterSword = ArenaState.CanAfford(player, "Gold", 8)
        payload.CoreExposedWarning = payload.OwnCoreAlive and not payload.HasPickaxe and not payload.HasStarterWeapon
        payload.OwnLoadoutHints = ArenaState.GetLoadoutHints(player)
        if phase ~= "Lobby" then
            payload.Standings = ArenaState.GetTeamStandings()
        end
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
    local activeTeamCount = getSupportedTeamCountForPlayers(#players)
    local selectedPlayers = {}
    local selectedTeams = {}
    local playerLimit = activeTeamCount * Config.Match.PreferredPlayersPerTeam

    ArenaState.MatchPlayers = {}
    ArenaState.ActiveTeamIds = {}

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
    local state = ensurePlayerState(player)
    state.Resources[resourceType] = math.max(0, (state.Resources[resourceType] or 0) + amount)
    ArenaState.BroadcastInventory(player)
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
    if state.TeamId ~= shopPart:GetAttribute("TeamId") then
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

    team.CoreHealth = math.max(0, team.CoreHealth - amount)
    local corePart = ArenaState.CoreInstances[teamId]
    if corePart then
        corePart:SetAttribute("CoreHealth", team.CoreHealth)
        corePart.Color = team.CoreHealth > 0 and team.Color:Lerp(Color3.new(1, 1, 1), 0.25) or Color3.fromRGB(75, 75, 75)
        updateCoreStatusVisual(
            corePart,
            team.CoreHealth > 0
                and string.format("Nucleo %d/%d", team.CoreHealth, Config.Match.MaxCoreHealth)
                or "Nucleo destruido"
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
    ArenaState.BroadcastInventory(player)
    ArenaState.BroadcastMatchState()
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

    if (state.Resources.Iron or 0) <= 0 and (state.Resources.Gold or 0) <= 0 then
        hints[#hints + 1] = Config.UI.Hints.NoResources
    end
    if ArenaState.CanAfford(player, "Iron", 16) then
        hints[#hints + 1] = Config.UI.Hints.CanBuyBlocks
    end
    if ArenaState.CanAfford(player, "Gold", 8) then
        hints[#hints + 1] = Config.UI.Hints.CanBuySword
    end
    if not ArenaState.PlayerHasTool(player, Config.UI.StarterRecommendations.PickaxeItemId) then
        hints[#hints + 1] = Config.UI.Hints.NeedPickaxe
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

return ArenaState
