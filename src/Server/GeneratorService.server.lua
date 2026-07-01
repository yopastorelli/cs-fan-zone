local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local pickupsFolder
local collectedDebounce = {}
local connectedGenerators = {}
local pickupCountByGenerator = {}
local pickupGeneratorByPart = {}

local function addPickupDetail(pickup, resourceType, resourceColor)
    if resourceType == "Emerald" then
        for _, offset in ipairs({
            Vector3.new(0, 0.9, 0),
            Vector3.new(-0.7, 0.2, 0),
            Vector3.new(0.7, 0.2, 0),
            Vector3.new(0, -0.5, 0),
        }) do
            local pixel = Instance.new("Part")
            pixel.Name = "EmeraldPixel"
            pixel.Size = Vector3.new(0.8, 0.8, 0.8)
            pixel.Color = resourceColor
            pixel.Material = Enum.Material.Neon
            pixel.CanCollide = false
            pixel.CanTouch = false
            pixel.CanQuery = false
            pixel.Anchored = false
            pixel.Massless = true
            pixel.CFrame = pickup.CFrame + offset
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = pickup
            weld.Part1 = pixel
            weld.Parent = pixel
            pixel.Parent = pickup
        end
    else
        local plate = Instance.new("Part")
        plate.Name = "PickupPlate"
        plate.Size = Vector3.new(pickup.Size.X * 0.72, 0.28, pickup.Size.Z * 0.72)
        plate.Color = resourceColor:Lerp(Color3.new(1, 1, 1), 0.14)
        plate.Material = Enum.Material.SmoothPlastic
        plate.CanCollide = false
        plate.CanTouch = false
        plate.CanQuery = false
        plate.Anchored = false
        plate.Massless = true
        plate.CFrame = pickup.CFrame + Vector3.new(0, pickup.Size.Y * 0.52, 0)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = pickup
        weld.Part1 = plate
        weld.Parent = plate
        plate.Parent = pickup
    end
end

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
    pickupGeneratorByPart[pickup] = generatorPart
    pickupCountByGenerator[generatorPart] = (pickupCountByGenerator[generatorPart] or 0) + 1
    addPickupDetail(pickup, generatorType.ResourceType, resourceDef.Color)

    local released = false
    local function releasePickup()
        if released then
            return
        end
        released = true
        local ownerGenerator = pickupGeneratorByPart[pickup]
        pickupGeneratorByPart[pickup] = nil
        if ownerGenerator then
            pickupCountByGenerator[ownerGenerator] = math.max(0, (pickupCountByGenerator[ownerGenerator] or 1) - 1)
        end
    end

    pickup.Destroying:Connect(releasePickup)

    pickup.Touched:Connect(function(hit)
        local character = hit and hit.Parent
        local player = character and Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end
        if not ArenaState.CanCollectResources(player) then
            return
        end

        local key = tostring(player.UserId) .. ":" .. pickup:GetDebugId()
        if collectedDebounce[key] then
            return
        end
        collectedDebounce[key] = true

        if pickup.Parent then
            local added = ArenaState.AddResource(player, pickup:GetAttribute("ResourceType"), pickup:GetAttribute("Amount"))
            if added then
                ArenaState.PushFeedback(player, "ResourceCollected", {
                    ResourceType = pickup:GetAttribute("ResourceType"),
                    Amount = pickup:GetAttribute("Amount"),
                })
                releasePickup()
                pickup:Destroy()
            end
        end

        task.delay(0.25, function()
            collectedDebounce[key] = nil
        end)
    end)
end

local function generatorLoop(generatorPart)
    if connectedGenerators[generatorPart] then
        return
    end
    connectedGenerators[generatorPart] = true
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

        local teamId = generatorPart:GetAttribute("TeamId")
        if teamId and not ArenaState.IsTeamActive(teamId) then
            continue
        end

        if (pickupCountByGenerator[generatorPart] or 0) < Config.Generators.MaxPickupsPerGenerator then
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

world.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") and descendant:GetAttribute("GeneratorType") then
        task.spawn(generatorLoop, descendant)
    end
end)
