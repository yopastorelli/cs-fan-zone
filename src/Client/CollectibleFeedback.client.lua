local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local collectibleCollected = Remotes.GetRemote("CollectibleCollected")
local poiActivated = Remotes.GetRemote("PoiActivated")
local missionStateUpdated = Remotes.GetRemote("MissionStateUpdated")
local finalRoomUnlocked = Remotes.GetRemote("FinalRoomUnlocked")

local hiddenCollectibles = {}
local activatedPois = {}

local function getWorld()
    return Workspace:FindFirstChild("CSFanZone")
end

local function findDescendantByName(root, targetName)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant.Name == targetName then
            return descendant
        end
    end

    return nil
end

local function fadeCollectible(collectibleId)
    hiddenCollectibles[collectibleId] = true

    local world = getWorld()
    if not world then
        return
    end

    local part = findDescendantByName(world, collectibleId)
    if not part or not part:IsA("BasePart") then
        return
    end

    part.Transparency = 0.8
    part.CanTouch = false
    part.CanQuery = false

    local glow = part:FindFirstChild("Glow")
    if glow then
        glow.Enabled = false
    end

    local billboard = part:FindFirstChild("Billboard")
    if billboard then
        billboard.Enabled = false
    end

    local prompt = part:FindFirstChild("CollectPrompt")
    if prompt then
        prompt.Enabled = false
    end
end

local function markPoiActivated(poiId)
    activatedPois[poiId] = true

    local world = getWorld()
    if not world then
        return
    end

    local part = findDescendantByName(world, poiId)
    if not part or not part:IsA("BasePart") then
        return
    end

    part.Material = Enum.Material.Neon
    part.Color = Config.UI.Theme.SuccessColor
end

local function pulsePoi(poiId)
    markPoiActivated(poiId)

    local world = getWorld()
    local part = world and findDescendantByName(world, poiId)
    if not part or not part:IsA("BasePart") then
        return
    end

    part.Color = Config.UI.Theme.SecretGlowColor
    task.delay(0.8, function()
        if part.Parent then
            part.Color = Config.UI.Theme.SuccessColor
        end
    end)
end

local function activateFinalCelebration()
    local world = getWorld()
    if not world then
        return
    end

    local room = world:FindFirstChild("FinalCelebrationRoom")
    if not room then
        return
    end

    local spot = room:FindFirstChild("SelfieSpot")
    if spot and spot:IsA("BasePart") then
        spot.Material = Enum.Material.Neon
        spot.Color = Config.UI.Theme.SecretGlowColor
    end

    local gate = room:FindFirstChild("FinalGate")
    if gate and gate:IsA("BasePart") then
        gate.Transparency = 0.55
        gate.Color = Config.UI.Theme.SecretGlowColor

        local gui = gate:FindFirstChild("SurfaceGui")
        local label = gui and gui:FindFirstChild("TextLabel")
        if label then
            label.Text = "Sala Final\nUse o portal"
        end
    end

    for _, descendant in ipairs(room:GetDescendants()) do
        if descendant:IsA("PointLight") and descendant.Name == "SecretLight" then
            descendant.Enabled = true
            descendant.Brightness = 3
            descendant.Range = 20
        elseif descendant:IsA("BasePart") and descendant.Name == "SecretCore" then
            descendant.Material = Enum.Material.Neon
            descendant.Color = Config.UI.Theme.SecretGlowColor
        end
    end
end

local function applyMissionState(payload)
    if typeof(payload) ~= "table" then
        return
    end

    if typeof(payload.CollectedIds) == "table" then
        for _, collectibleId in ipairs(payload.CollectedIds) do
            fadeCollectible(collectibleId)
        end
    end

    if typeof(payload.ActivatedPOIIds) == "table" then
        for _, poiId in ipairs(payload.ActivatedPOIIds) do
            markPoiActivated(poiId)
        end
    end

    if payload.IsComplete then
        activateFinalCelebration()
    end
end

local function reapplyLocalState()
    for collectibleId in pairs(hiddenCollectibles) do
        fadeCollectible(collectibleId)
    end

    for poiId in pairs(activatedPois) do
        markPoiActivated(poiId)
    end
end

local function watchWorld()
    local world = Workspace:FindFirstChild("CSFanZone") or Workspace:WaitForChild("CSFanZone", 10)
    if not world then
        return
    end

    world.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            task.defer(reapplyLocalState)
        end
    end)
end

collectibleCollected.OnClientEvent:Connect(function(payload)
    if typeof(payload) == "table" and payload.Id then
        fadeCollectible(payload.Id)
    end
end)

poiActivated.OnClientEvent:Connect(function(payload)
    if typeof(payload) == "table" and payload.Id then
        pulsePoi(payload.Id)
    end
end)

finalRoomUnlocked.OnClientEvent:Connect(applyMissionState)
missionStateUpdated.OnClientEvent:Connect(applyMissionState)

watchWorld()
