local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local TelemetryService = {}

local playerEvents = {}
local funnelSteps = {}

local function ensurePlayerTables(player)
    playerEvents[player] = playerEvents[player] or {}
    funnelSteps[player] = funnelSteps[player] or {}
    return playerEvents[player], funnelSteps[player]
end

local function tryLogCustomEvent(player, eventName)
    local ok = pcall(function()
        AnalyticsService:LogCustomEvent(player, eventName)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        AnalyticsService:LogCustomEvent(player, eventName, 1)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        AnalyticsService:LogCustomEvent(player, eventName, 1, {})
    end)
    return ok
end

local function tryLogOnboardingStep(player, stepIndex, stepName)
    local funnelName = Config.Analytics.OnboardingFunnelName
    local ok = pcall(function()
        AnalyticsService:LogOnboardingFunnelStepEvent(player, funnelName, stepIndex, stepName)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        AnalyticsService:LogFunnelStepEvent(player, funnelName, stepIndex, stepName)
    end)
    return ok
end

function TelemetryService.TrackOneShot(player, eventName)
    if not player or not eventName then
        return
    end
    local events = ensurePlayerTables(player)
    if events[eventName] then
        return
    end
    events[eventName] = true
    tryLogCustomEvent(player, eventName)
end

function TelemetryService.TrackFunnelStep(player, stepIndex, stepName, eventName)
    if not player or not stepIndex then
        return
    end
    local _, steps = ensurePlayerTables(player)
    if steps[stepIndex] then
        return
    end
    steps[stepIndex] = true
    tryLogOnboardingStep(player, stepIndex, stepName or ("step_" .. tostring(stepIndex)))
    if eventName then
        TelemetryService.TrackOneShot(player, eventName)
    end
end

function TelemetryService.TrackClientEvent(player, eventName)
    if not player or not eventName then
        return
    end
    if Config.Analytics.AllowedClientEvents[eventName] ~= true then
        return
    end
    TelemetryService.TrackOneShot(player, eventName)
end

Players.PlayerRemoving:Connect(function(player)
    playerEvents[player] = nil
    funnelSteps[player] = nil
end)

do
    local remotes = Remotes.GetAll()
    remotes.TelemetryRequested.OnServerEvent:Connect(function(player, payload)
        if typeof(payload) ~= "table" or typeof(payload.EventName) ~= "string" then
            return
        end
        TelemetryService.TrackClientEvent(player, payload.EventName)
    end)
end

return TelemetryService
