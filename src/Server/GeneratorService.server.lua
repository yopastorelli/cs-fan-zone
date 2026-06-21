local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local pickupsFolder
local collectedDebounce = {}

local function ensurePickupsFolder()
    local world = Workspace:WaitForChild("CSFanZone")
    pickupsFolder = world:FindFirstChild("GeneratorDrops")
    if pickupsFolder then
        return pickupsFolder
    end

    pickupsFolder = Instance.new("Folder")
    pickupsFolder.Name = "GeneratorDrops"
    pickupsFolder.Parent = world
    return pickupsFolder
end

local function createPickup(generatorPart, generatorTypeName)
    local generatorType = Config.Generators.GeneratorTypes[generatorTypeName]
    local resourceDef = Config.Generators.ResourceDefinitions[generatorType.ResourceType]
    local pickup = Instance.new("Part")
    pickup.Name = generatorType.ResourceType .. "Pickup"
    pickup.Size = resourceDef.PickupSize
    pickup.CFrame = generatorPart.CFrame + Vector3.new(0, 2, 0)
    pickup.Color = resourceDef.Color
    pickup.Material = resourceDef.Material
    pickup.Shape = Enum.PartType.Block
    pickup.Anchored = false
    pickup.CanCollide = true
    pickup:SetAttribute("ResourceType", generatorType.ResourceType)
    pickup:SetAttribute("Amount", generatorType.Amount)
    pickup.Parent = ensurePickupsFolder()

    pickup.Touched:Connect(function(hit)
        local character = hit and hit.Parent
        local player = character and game:GetService("Players"):GetPlayerFromCharacter(character)
        if not player then
            return
        end

        local key = tostring(player.UserId) .. ":" .. pickup:GetDebugId()
        if collectedDebounce[key] then
            return
        end
        collectedDebounce[key] = true

        if pickup.Parent then
            ArenaState.AddResource(player, pickup:GetAttribute("ResourceType"), pickup:GetAttribute("Amount"))
            pickup:Destroy()
        end

        task.delay(0.25, function()
            collectedDebounce[key] = nil
        end)
    end)
end

local function countPickupsNear(generatorPart, resourceType)
    local count = 0
    for _, child in ipairs(ensurePickupsFolder():GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("ResourceType") == resourceType then
            if (child.Position - generatorPart.Position).Magnitude <= 10 then
                count += 1
            end
        end
    end
    return count
end

local function generatorLoop(generatorPart)
    local generatorTypeName = generatorPart:GetAttribute("GeneratorType")
    local generatorType = Config.Generators.GeneratorTypes[generatorTypeName]
    if not generatorType then
        return
    end

    while generatorPart.Parent do
        local interval = generatorType.SpawnInterval
        local teamId = generatorPart:GetAttribute("TeamId")
        if teamId and generatorTypeName ~= "MidEmerald" then
            interval *= ArenaState.GetForgeMultiplier(teamId)
        end

        task.wait(interval)
        if not generatorPart.Parent then
            break
        end

        if countPickupsNear(generatorPart, generatorType.ResourceType) < Config.Generators.MaxPickupsPerGenerator then
            createPickup(generatorPart, generatorTypeName)
        end
    end
end

local world = Workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    if descendant:IsA("BasePart") and descendant:GetAttribute("GeneratorType") then
        task.spawn(generatorLoop, descendant)
    end
end
