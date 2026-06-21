local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local WorldBuilder = {}

function WorldBuilder.MakeFolder(parent, name)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

function WorldBuilder.MakePart(parent, name, size, cframe, color, material, options)
    options = options or {}

    local part = Instance.new(options.ClassName or "Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = options.Anchored ~= false
    part.CanCollide = options.CanCollide ~= false
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    if options.Shape then
        part.Shape = options.Shape
    end
    if options.Transparency then
        part.Transparency = options.Transparency
    end
    if options.CastShadow ~= nil then
        part.CastShadow = options.CastShadow
    end

    part.Parent = parent
    return part
end

function WorldBuilder.AddSurfaceText(part, face, text, textColor, pixelsPerStud)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "SurfaceGui"
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = pixelsPerStud or 32
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "TextLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = textColor or Config.UI.Theme.TextColor
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    return gui
end

function WorldBuilder.AddBillboard(part, name, text, color, size, studsOffset)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = name
    billboard.Size = size or UDim2.fromOffset(220, 66)
    billboard.StudsOffset = studsOffset or Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Config.UI.Theme.PanelColor
    label.BackgroundTransparency = 0.08
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color or Config.UI.Theme.TextColor
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    return billboard
end

function WorldBuilder.AddPrompt(parent, name, actionText, objectText, holdDuration)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = name
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = holdDuration or 0
    prompt.Parent = parent
    return prompt
end

function WorldBuilder.AddPointLight(parent, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness or 1.2
    light.Range = range or 18
    light.Shadows = true
    light.Parent = parent
    return light
end

function WorldBuilder.AddParticles(parent, color, rate, lifetime)
    local attachment = Instance.new("Attachment")
    attachment.Name = "VFXAttachment"
    attachment.Parent = parent

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AmbientParticles"
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = 0.45
    emitter.Rate = rate or 4
    emitter.Lifetime = NumberRange.new(lifetime or 1.5, (lifetime or 1.5) + 0.5)
    emitter.Speed = NumberRange.new(0.6, 1.5)
    emitter.SpreadAngle = Vector2.new(18, 18)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
    return emitter
end

function WorldBuilder.BuildIsland(parent, name, centerPosition, size, kit, options)
    options = options or {}
    local folder = WorldBuilder.MakeFolder(parent, name)

    WorldBuilder.MakePart(folder, "IslandBase", size, CFrame.new(centerPosition + Vector3.new(0, -3, 0)), kit.Primary, kit.Material)
    WorldBuilder.MakePart(folder, "IslandForwardMass", Vector3.new(size.X * 0.52, 5, size.Z * 0.34), CFrame.new(centerPosition + Vector3.new(0, -2, -size.Z * 0.46)), kit.Primary:Lerp(kit.Secondary, 0.22), kit.Material)
    WorldBuilder.MakePart(folder, "IslandLeftMass", Vector3.new(size.X * 0.34, 5, size.Z * 0.58), CFrame.new(centerPosition + Vector3.new(-size.X * 0.42, -2.3, 0)), kit.Primary, kit.Material)
    WorldBuilder.MakePart(folder, "IslandRightMass", Vector3.new(size.X * 0.34, 5, size.Z * 0.58), CFrame.new(centerPosition + Vector3.new(size.X * 0.42, -2.3, 0)), kit.Primary:Lerp(kit.Rim, 0.12), kit.Material)

    WorldBuilder.MakePart(folder, "FrontRim", Vector3.new(size.X + 10, 3, 6), CFrame.new(centerPosition + Vector3.new(0, -5, -size.Z / 2 - 2)), kit.Rim, Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "BackRim", Vector3.new(size.X + 10, 3, 6), CFrame.new(centerPosition + Vector3.new(0, -5, size.Z / 2 + 2)), kit.Rim, Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "LeftRim", Vector3.new(6, 3, size.Z + 10), CFrame.new(centerPosition + Vector3.new(-size.X / 2 - 2, -5, 0)), kit.Rim, Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "RightRim", Vector3.new(6, 3, size.Z + 10), CFrame.new(centerPosition + Vector3.new(size.X / 2 + 2, -5, 0)), kit.Rim, Enum.Material.Rock)

    for index, offset in ipairs({
        Vector3.new(-size.X * 0.28, -14, -size.Z * 0.26),
        Vector3.new(size.X * 0.28, -14, -size.Z * 0.22),
        Vector3.new(-size.X * 0.18, -15, size.Z * 0.28),
        Vector3.new(size.X * 0.18, -15, size.Z * 0.28),
        Vector3.new(0, -18, 0),
    }) do
        local support = WorldBuilder.MakePart(folder, "UndersideRock" .. index, Vector3.new(9, 18 + index, 9), CFrame.new(centerPosition + offset), kit.Underside, Enum.Material.Rock, {
            Shape = Enum.PartType.Cylinder,
        })
        support.CFrame *= CFrame.Angles(0, math.rad(index * 17), 0)
    end

    if options.Glow then
        local glow = WorldBuilder.MakePart(folder, "IslandGlow", Vector3.new(size.X * 0.82, 1, size.Z * 0.82), CFrame.new(centerPosition + Vector3.new(0, 0.25, 0)), kit.Accent, Enum.Material.Neon, {
            CanCollide = false,
            Transparency = 0.78,
            CastShadow = false,
        })
        WorldBuilder.AddPointLight(glow, kit.Accent, 0.8, math.max(size.X, size.Z) * 0.45)
    end

    return folder
end

function WorldBuilder.BuildRouteMarkers(parent, fromPosition, toPosition, color)
    local delta = toPosition - fromPosition
    for index = 1, 5 do
        local alpha = index / 6
        local position = fromPosition + (delta * alpha) + Vector3.new(0, 4 + (index % 2), 0)
        WorldBuilder.MakePart(parent, "RouteMarker" .. index, Vector3.new(5, 0.6, 5), CFrame.new(position), color, Enum.Material.Neon, {
            CanCollide = false,
            Transparency = 0.35,
            CastShadow = false,
        })
    end
end

function WorldBuilder.BuildGenerator(parent, name, position, color, resourceName)
    local pad = WorldBuilder.MakePart(parent, name .. "Pad", Vector3.new(9, 1, 9), CFrame.new(position + Vector3.new(0, 0.1, 0)), color:Lerp(Color3.new(0, 0, 0), 0.35), Enum.Material.Metal)
    local generator = WorldBuilder.MakePart(parent, name, Vector3.new(4, 1.2, 4), CFrame.new(position + Vector3.new(0, 1.2, 0)), color, Enum.Material.Neon)
    WorldBuilder.AddBillboard(generator, name .. "Billboard", resourceName, VisualKit.Global.TextLight, UDim2.fromOffset(170, 50), Vector3.new(0, 4, 0))
    WorldBuilder.AddPointLight(generator, color, 1.25, 18)
    WorldBuilder.AddParticles(generator, color, 3, 1.2)
    pad:SetAttribute("GameplayDecor", true)
    return generator
end

function WorldBuilder.BuildShopStand(parent, name, position, color, title)
    local stand = WorldBuilder.MakePart(parent, name, Vector3.new(7, 7, 6), CFrame.new(position), color, Enum.Material.SmoothPlastic)
    local counter = WorldBuilder.MakePart(parent, name .. "Counter", Vector3.new(10, 2, 5), CFrame.new(position + Vector3.new(0, -3, -4)), color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Metal)
    local roof = WorldBuilder.MakePart(parent, name .. "Roof", Vector3.new(12, 1.2, 8), CFrame.new(position + Vector3.new(0, 4.5, 0)), color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Neon, {
        Transparency = 0.08,
    })
    WorldBuilder.AddBillboard(stand, name .. "Billboard", title, VisualKit.Global.TextLight, UDim2.fromOffset(190, 56), Vector3.new(0, 6, 0))
    WorldBuilder.AddPointLight(roof, color, 0.8, 16)
    counter:SetAttribute("GameplayDecor", true)
    roof:SetAttribute("GameplayDecor", true)
    return stand
end

function WorldBuilder.BuildCore(parent, position, color)
    local pedestal = WorldBuilder.MakePart(parent, "CorePedestal", Vector3.new(14, 2, 14), CFrame.new(position + Vector3.new(0, -3.4, 0)), color:Lerp(Color3.new(0, 0, 0), 0.35), Enum.Material.Metal)
    local aura = WorldBuilder.MakePart(parent, "CoreAura", Vector3.new(11, 0.4, 11), CFrame.new(position + Vector3.new(0, -2.1, 0)), color, Enum.Material.Neon, {
        CanCollide = false,
        Transparency = 0.45,
        CastShadow = false,
    })
    local core = WorldBuilder.MakePart(parent, "Core", Vector3.new(8, 8, 8), CFrame.new(position), color, Enum.Material.ForceField, {
        Shape = Enum.PartType.Ball,
    })
    WorldBuilder.AddBillboard(core, "CoreStatus", "Nucleo 6/6", VisualKit.Global.TextLight, UDim2.fromOffset(210, 58), Vector3.new(0, 6, 0))
    WorldBuilder.AddPointLight(core, color, 1.2, 22)
    WorldBuilder.AddParticles(core, color, 2, 1.6)
    pedestal:SetAttribute("GameplayDecor", true)
    aura:SetAttribute("GameplayDecor", true)
    return core
end

local function makeFlower(parent, position, color)
    WorldBuilder.MakePart(parent, "FlowerStem", Vector3.new(0.3, 2, 0.3), CFrame.new(position + Vector3.new(0, 1, 0)), Color3.fromRGB(73, 143, 68), Enum.Material.Grass, {
        CanCollide = false,
    })
    WorldBuilder.MakePart(parent, "FlowerBloom", Vector3.new(1, 1, 1), CFrame.new(position + Vector3.new(0, 2.15, 0)), color, Enum.Material.SmoothPlastic, {
        Shape = Enum.PartType.Ball,
        CanCollide = false,
    })
end

local function makeTree(parent, position, trunkColor, leafColor)
    WorldBuilder.MakePart(parent, "TreeTrunk", Vector3.new(2, 8, 2), CFrame.new(position + Vector3.new(0, 4, 0)), trunkColor, Enum.Material.Wood)
    WorldBuilder.MakePart(parent, "TreeCrownLower", Vector3.new(8, 5, 8), CFrame.new(position + Vector3.new(0, 9, 0)), leafColor, Enum.Material.LeafyGrass, {
        Shape = Enum.PartType.Ball,
    })
    WorldBuilder.MakePart(parent, "TreeCrownTop", Vector3.new(5, 4, 5), CFrame.new(position + Vector3.new(0, 12, 0)), leafColor:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.LeafyGrass, {
        Shape = Enum.PartType.Ball,
    })
end

local function makeCrystal(parent, position, color)
    local crystal = WorldBuilder.MakePart(parent, "Crystal", Vector3.new(3, 12, 3), CFrame.new(position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, math.rad(45), 0), color, Enum.Material.Glass)
    crystal.Transparency = 0.18
    WorldBuilder.AddPointLight(crystal, color, 0.7, 12)
end

local function makeMushroom(parent, position, stemColor, capColor)
    WorldBuilder.MakePart(parent, "MushroomStem", Vector3.new(3, 7, 3), CFrame.new(position + Vector3.new(0, 3.5, 0)), stemColor, Enum.Material.SmoothPlastic, {
        Shape = Enum.PartType.Cylinder,
    })
    WorldBuilder.MakePart(parent, "MushroomCap", Vector3.new(10, 5, 10), CFrame.new(position + Vector3.new(0, 8, 0)), capColor, Enum.Material.SmoothPlastic, {
        Shape = Enum.PartType.Ball,
    })
end

function WorldBuilder.BuildBiomeProps(parent, centerPosition, kit)
    local offsets = {
        Vector3.new(-24, 1, -22),
        Vector3.new(24, 1, -20),
        Vector3.new(-28, 1, 18),
        Vector3.new(28, 1, 20),
        Vector3.new(-10, 1, 30),
        Vector3.new(10, 1, -32),
        Vector3.new(-34, 1, 2),
        Vector3.new(34, 1, -2),
    }

    for index, offset in ipairs(offsets) do
        local position = centerPosition + offset
        if kit.PropStyle == "flowers" then
            makeFlower(parent, position, index % 2 == 0 and kit.Accent or Color3.fromRGB(255, 220, 110))
        elseif kit.PropStyle == "dunes" then
            WorldBuilder.MakePart(parent, "DuneLayer", Vector3.new(12, 1.2, 5), CFrame.new(position), kit.Secondary, Enum.Material.Sand)
        elseif kit.PropStyle == "pines" then
            makeTree(parent, position, Color3.fromRGB(86, 63, 44), kit.Primary:Lerp(Color3.new(0, 0, 0), 0.18))
        elseif kit.PropStyle == "jungle" then
            makeTree(parent, position, Color3.fromRGB(82, 55, 35), kit.Secondary)
        elseif kit.PropStyle == "crystals" then
            makeCrystal(parent, position, kit.Accent)
        elseif kit.PropStyle == "mushrooms" then
            makeMushroom(parent, position, Color3.fromRGB(232, 214, 188), kit.Secondary)
        end
    end
end

function WorldBuilder.BuildLandmark(parent, centerPosition, kit, labelText)
    local basePosition = centerPosition + Vector3.new(0, 2, 30)
    if kit.Landmark == "windmill" then
        WorldBuilder.MakePart(parent, "LandmarkTower", Vector3.new(5, 24, 5), CFrame.new(basePosition + Vector3.new(0, 12, 0)), kit.Secondary, Enum.Material.Wood)
        WorldBuilder.MakePart(parent, "LandmarkBladeA", Vector3.new(2, 24, 1), CFrame.new(basePosition + Vector3.new(0, 24, -2)), kit.Accent, Enum.Material.SmoothPlastic)
        WorldBuilder.MakePart(parent, "LandmarkBladeB", Vector3.new(24, 2, 1), CFrame.new(basePosition + Vector3.new(0, 24, -2)), kit.Accent, Enum.Material.SmoothPlastic)
    elseif kit.Landmark == "obelisk" then
        WorldBuilder.MakePart(parent, "LandmarkObelisk", Vector3.new(8, 34, 8), CFrame.new(basePosition + Vector3.new(0, 17, 0)), kit.Accent, Enum.Material.Sandstone)
    elseif kit.Landmark == "pine" then
        makeTree(parent, basePosition, Color3.fromRGB(76, 56, 40), kit.Secondary)
        WorldBuilder.MakePart(parent, "LandmarkSpire", Vector3.new(8, 14, 8), CFrame.new(basePosition + Vector3.new(0, 24, 0)), kit.Primary, Enum.Material.LeafyGrass, {
            Shape = Enum.PartType.Cylinder,
        })
    elseif kit.Landmark == "canopy" then
        makeTree(parent, basePosition, Color3.fromRGB(76, 54, 35), kit.Secondary)
        makeTree(parent, basePosition + Vector3.new(8, 0, -3), Color3.fromRGB(76, 54, 35), kit.Primary)
    elseif kit.Landmark == "crystal" then
        makeCrystal(parent, basePosition, kit.Accent)
        makeCrystal(parent, basePosition + Vector3.new(7, 0, -5), kit.Secondary)
    elseif kit.Landmark == "mushroom" then
        makeMushroom(parent, basePosition, Color3.fromRGB(230, 214, 196), kit.Secondary)
        makeMushroom(parent, basePosition + Vector3.new(8, 0, -4), Color3.fromRGB(220, 205, 188), kit.Accent)
    end

    local banner = WorldBuilder.MakePart(parent, "BiomeBanner", Vector3.new(24, 9, 1), CFrame.new(centerPosition + Vector3.new(0, 16, -34)), kit.Accent, Enum.Material.Neon, {
        CanCollide = false,
    })
    WorldBuilder.AddSurfaceText(banner, Enum.NormalId.Front, labelText, VisualKit.Global.TextDark, 28)
end

return WorldBuilder
