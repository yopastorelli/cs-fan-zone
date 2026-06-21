local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Counter = require(Shared:WaitForChild("Counter"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local remotes = Remotes.GetAll()
local states = {}
local initialized = false

local collectibleLookup = {}
for _, collectible in ipairs(Config.Collectibles) do
    collectibleLookup[collectible.Id] = collectible
end

local poiLookup = {}
for _, poi in ipairs(Config.POIs) do
    poiLookup[poi.Id] = poi
end

local MissionState = {}

local function getOrCreateState(player)
    local state = states[player]
    if state then
        return state
    end

    state = {
        Collectibles = Counter.new(Config.Mission.CollectibleGoal),
        POIs = Counter.new(Config.Mission.PoiGoal),
        Complete = false,
    }

    states[player] = state
    return state
end

local function updateStats(player)
    local state = getOrCreateState(player)
    local leaderstats = player:FindFirstChild("leaderstats")

    if leaderstats then
        local memories = leaderstats:FindFirstChild("Memories")
        local pois = leaderstats:FindFirstChild("POIs")

        if memories then
            memories.Value = state.Collectibles.count
        end

        if pois then
            pois.Value = state.POIs.count
        end
    end

    player:SetAttribute("MemoriesFound", state.Collectibles.count)
    player:SetAttribute("POIsActivated", state.POIs.count)
    player:SetAttribute("MissionComplete", state.Complete)
end

local function serializeState(player, message)
    local state = getOrCreateState(player)
    local objectiveText = state.Complete and Config.Mission.PhotoPromptMessage or Config.Mission.ObjectiveText
    local statusText = state.Complete and "Final liberado" or "Explorando"

    return {
        Objective = objectiveText,
        Status = statusText,
        CollectiblesFound = state.Collectibles.count,
        CollectibleGoal = state.Collectibles.goal,
        POIsActivated = state.POIs.count,
        POIGoal = state.POIs.goal,
        IsComplete = state.Complete,
        CollectedIds = Counter.ids(state.Collectibles),
        ActivatedPOIIds = Counter.ids(state.POIs),
        Message = message or Config.Mission.StartMessage,
    }
end

local function sendState(player, message)
    updateStats(player)
    remotes.MissionStateUpdated:FireClient(player, serializeState(player, message))
end

local function checkCompletion(player)
    local state = getOrCreateState(player)
    if state.Complete then
        return false
    end

    if Counter.isComplete(state.Collectibles) and Counter.isComplete(state.POIs) then
        state.Complete = true
        updateStats(player)
        remotes.FinalRoomUnlocked:FireClient(player, serializeState(player, Config.Mission.CompletionMessage))
        sendState(player, Config.Mission.CompletionMessage)
        return true
    end

    return false
end

function MissionState.InitializePlayer(player)
    getOrCreateState(player)
    updateStats(player)

    task.delay(2, function()
        if player.Parent then
            sendState(player, Config.Mission.StartMessage)
        end
    end)
end

function MissionState.RemovePlayer(player)
    states[player] = nil
end

function MissionState.Collect(player, collectibleId)
    local collectible = collectibleLookup[collectibleId]
    if not collectible then
        return false
    end

    local state = getOrCreateState(player)
    local changed = Counter.collect(state.Collectibles, collectibleId)

    if not changed then
        sendState(player, Config.Mission.DuplicateCollectibleMessage)
        return false
    end

    local message = string.format("%s registrada.", collectible.DisplayName)
    updateStats(player)
    remotes.CollectibleCollected:FireClient(player, {
        Id = collectible.Id,
        DisplayName = collectible.DisplayName,
        Count = state.Collectibles.count,
        Goal = state.Collectibles.goal,
        Message = message,
    })

    if not checkCompletion(player) then
        sendState(player, message)
    end

    return true
end

function MissionState.ActivatePOI(player, poiId)
    local poi = poiLookup[poiId]
    if not poi then
        return false
    end

    local state = getOrCreateState(player)
    local changed = Counter.collect(state.POIs, poiId)

    if not changed then
        sendState(player, Config.Mission.DuplicatePoiMessage)
        return false
    end

    updateStats(player)
    remotes.PoiActivated:FireClient(player, {
        Id = poi.Id,
        DisplayName = poi.DisplayName,
        Count = state.POIs.count,
        Goal = state.POIs.goal,
        Message = poi.Message,
    })

    if not checkCompletion(player) then
        sendState(player, poi.Message)
    end

    return true
end

function MissionState.IsComplete(player)
    return getOrCreateState(player).Complete
end

function MissionState.SendState(player, message)
    sendState(player, message)
end

function MissionState.Initialize()
    if initialized then
        return
    end

    initialized = true

    Players.PlayerAdded:Connect(MissionState.InitializePlayer)
    Players.PlayerRemoving:Connect(MissionState.RemovePlayer)

    for _, player in ipairs(Players:GetPlayers()) do
        MissionState.InitializePlayer(player)
    end
end

return MissionState
