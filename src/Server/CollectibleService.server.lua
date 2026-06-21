local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MissionState = require(script.Parent:WaitForChild("MissionState"))

local connected = {}
local touchDebounce = {}

local function getPlayerFromHit(hit)
    local character = hit and hit.Parent
    if not character then
        return nil
    end

    return Players:GetPlayerFromCharacter(character)
end

local function collectForPlayer(player, collectibleId)
    if not player or typeof(collectibleId) ~= "string" then
        return
    end

    MissionState.Collect(player, collectibleId)
end

local function connectPrompt(part, prompt)
    if connected[prompt] then
        return
    end

    connected[prompt] = true
    prompt.Triggered:Connect(function(player)
        collectForPlayer(player, part:GetAttribute("CollectibleId"))
    end)
end

local function connectCollectible(part)
    if not part:IsA("BasePart") then
        return
    end

    local collectibleId = part:GetAttribute("CollectibleId")
    if typeof(collectibleId) ~= "string" then
        return
    end

    if connected[part] then
        return
    end

    connected[part] = true

    part.Touched:Connect(function(hit)
        local player = getPlayerFromHit(hit)
        if not player then
            return
        end

        local key = tostring(player.UserId) .. ":" .. collectibleId
        if touchDebounce[key] then
            return
        end

        touchDebounce[key] = true
        collectForPlayer(player, collectibleId)

        task.delay(0.75, function()
            touchDebounce[key] = nil
        end)
    end)

    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("ProximityPrompt") then
            connectPrompt(part, child)
        end
    end

    part.ChildAdded:Connect(function(child)
        if child:IsA("ProximityPrompt") then
            connectPrompt(part, child)
        end
    end)
end

local world = Workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    connectCollectible(descendant)
end

world.DescendantAdded:Connect(connectCollectible)
