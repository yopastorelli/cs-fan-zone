local Workspace = game:GetService("Workspace")

local MissionState = require(script.Parent:WaitForChild("MissionState"))

local connected = {}

local function connectPrompt(prompt)
    if connected[prompt] then
        return
    end

    local parent = prompt.Parent
    local poiId = parent and parent:GetAttribute("PoiId")
    if typeof(poiId) ~= "string" then
        return
    end

    connected[prompt] = true
    prompt.Triggered:Connect(function(player)
        MissionState.ActivatePOI(player, poiId)
    end)
end

local function scan(instance)
    if instance:IsA("ProximityPrompt") then
        connectPrompt(instance)
    end
end

local world = Workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    scan(descendant)
end

world.DescendantAdded:Connect(scan)
