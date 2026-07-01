local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local WorldBuilder = {}
local activeQualityTier = ((Config.Visual and Config.Visual.VisualQualityDefault) or "Low")

local function getQualityTier()
    return VisualKit.QualityTiers[activeQualityTier] and VisualKit.QualityTiers[activeQualityTier] or VisualKit.QualityTiers.Low
end

local function isLowTier()
    return activeQualityTier == "Low"
end

local function shouldEnableBillboard(options)
    local tier = getQualityTier()
    if options.EnableBillboard == false then
        return false
    end
    if options.Category == "PureDecor" then
        return tier.RouteBillboards
    end
    return tier.GameplayBillboards
end

local function shouldEnableLight(options)
    local tier = getQualityTier()
    if options.EnableLight == false then
        return false
    end
    if options.Category == "PureDecor" then
        return tier.DecorativeLights
    end
    return true
end

local function shouldEnableParticles(options)
    local tier = getQualityTier()
    if options.EnableParticles == false then
        return false
    end
    if options.Category == "PureDecor" then
        return tier.DecorativeParticles
    end
    return true
end

function WorldBuilder.SetQualityTier(tier)
    if VisualKit.QualityTiers[tier] then
        activeQualityTier = tier
    end
end

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

function WorldBuilder.AddDoubleSurfaceText(part, text, textColor, pixelsPerStud)
    WorldBuilder.AddSurfaceText(part, Enum.NormalId.Front, text, textColor, pixelsPerStud)
    WorldBuilder.AddSurfaceText(part, Enum.NormalId.Back, text, textColor, pixelsPerStud)
end

function WorldBuilder.AddBillboard(part, name, text, color, size, studsOffset, options)
    options = options or {}
    if not shouldEnableBillboard(options) then
        return nil
    end
    local tier = getQualityTier()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = name
    billboard.Size = size or UDim2.fromOffset(220, 66)
    billboard.StudsOffset = studsOffset or Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = options.AlwaysOnTop == true
    billboard.MaxDistance = math.floor((options.MaxDistance or 42) * tier.BillboardDistanceScale)
    billboard.LightInfluence = options.LightInfluence or 0
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Config.UI.Theme.PanelColor
    label.BackgroundTransparency = options.BackgroundTransparency or 0.14
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
    local options = type(range) == "table" and range or {}
    local actualRange = type(range) == "number" and range or options.Range
    if not shouldEnableLight(options) then
        return nil
    end
    local tier = getQualityTier()
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = (brightness or 1.2) * tier.LightBrightnessScale
    light.Range = (actualRange or 18) * tier.LightRangeScale
    light.Shadows = not isLowTier()
    light.Parent = parent
    return light
end

function WorldBuilder.AddParticles(parent, color, rate, lifetime, options)
    options = options or {}
    if not shouldEnableParticles(options) then
        return nil
    end
    local tier = getQualityTier()
    local attachment = Instance.new("Attachment")
    attachment.Name = "VFXAttachment"
    attachment.Parent = parent

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AmbientParticles"
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = 0.45
    emitter.Rate = (rate or 4) * tier.ParticleRateScale
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
    local surfaceRules = VisualKit.BiomeSurfaceRules[name:lower()] or VisualKit.BiomeSurfaceRules[kit.PropStyle == "flowers" and "planicie" or "center"] or {}
    local topMaterial = surfaceRules.TopMaterial or kit.Material
    local midMaterial = surfaceRules.MidMaterial or kit.DetailMaterial or Enum.Material.Ground
    local sideMaterial = surfaceRules.SideMaterial or Enum.Material.Rock
    local accentMaterial = surfaceRules.AccentMaterial or Enum.Material.WoodPlanks

    local baseY = centerPosition.Y
    local soilColor = kit.Secondary or kit.Primary

    WorldBuilder.MakePart(folder, "StoneMass", Vector3.new(size.X + 16, 14, size.Z + 16), CFrame.new(centerPosition + Vector3.new(0, -7, 0)), kit.Underside, sideMaterial)
    WorldBuilder.MakePart(folder, "SoilLayer", Vector3.new(size.X + 4, 4, size.Z + 4), CFrame.new(centerPosition + Vector3.new(0, -1.2, 0)), soilColor, midMaterial)
    WorldBuilder.MakePart(folder, "TopPlateau", Vector3.new(size.X - 8, 2, size.Z - 8), CFrame.new(centerPosition + Vector3.new(0, 1.2, 0)), kit.Primary, topMaterial)
    WorldBuilder.MakePart(folder, "CenterPlateau", Vector3.new(size.X * 0.54, 2, size.Z * 0.52), CFrame.new(centerPosition + Vector3.new(0, 3.1, 0)), kit.Primary:Lerp(Color3.new(1, 1, 1), 0.04), topMaterial)
    WorldBuilder.MakePart(folder, "UpperStrataNorth", Vector3.new(size.X * 0.34, 2, 12), CFrame.new(centerPosition + Vector3.new(0, 4.9, -size.Z * 0.18)), kit.Primary:Lerp(kit.Accent, 0.08), topMaterial)
    WorldBuilder.MakePart(folder, "UpperStrataSouth", Vector3.new(size.X * 0.3, 2, 12), CFrame.new(centerPosition + Vector3.new(0, 4.9, size.Z * 0.18)), kit.Primary:Lerp(soilColor, 0.06), topMaterial)

    local terraceHeight = 2
    local terraceDepth = 8
    for index, data in ipairs({
        { "Front", Vector3.new(0, baseY + 1.1, -size.Z * 0.36), Vector3.new(size.X * 0.62, terraceHeight, terraceDepth) },
        { "Back", Vector3.new(0, baseY + 1.1, size.Z * 0.36), Vector3.new(size.X * 0.58, terraceHeight, terraceDepth) },
        { "Left", Vector3.new(-size.X * 0.36, baseY + 1.1, 0), Vector3.new(terraceDepth, terraceHeight, size.Z * 0.58) },
        { "Right", Vector3.new(size.X * 0.36, baseY + 1.1, 0), Vector3.new(terraceDepth, terraceHeight, size.Z * 0.58) },
    }) do
        WorldBuilder.MakePart(folder, data[1] .. "Terrace", data[3], CFrame.new(data[2]), kit.Primary:Lerp(soilColor, 0.18), topMaterial)
        WorldBuilder.MakePart(folder, data[1] .. "Rim", data[3] + Vector3.new(2, 2, 2), CFrame.new(data[2] - Vector3.new(0, 2.1, 0)), kit.Rim, sideMaterial)
        WorldBuilder.MakePart(folder, data[1] .. "Step", data[3] - Vector3.new(4, 0.4, 4), CFrame.new(data[2] + Vector3.new(0, 2.1, 0)), kit.Primary:Lerp(Color3.new(1, 1, 1), 0.02), topMaterial, {
            CanCollide = false,
        })
    end

    for index, offset in ipairs({
        Vector3.new(-size.X * 0.28, 4.4, -size.Z * 0.28),
        Vector3.new(size.X * 0.28, 4.4, -size.Z * 0.22),
        Vector3.new(-size.X * 0.22, 4.4, size.Z * 0.24),
        Vector3.new(size.X * 0.24, 4.4, size.Z * 0.28),
        Vector3.new(0, 4.4, -size.Z * 0.34),
        Vector3.new(0, 4.4, size.Z * 0.32),
    }) do
        WorldBuilder.MakePart(folder, "VoxelCap" .. index, Vector3.new(6, 2, 6), CFrame.new(centerPosition + offset), kit.Accent:Lerp(kit.Primary, 0.28), topMaterial)
    end

    for index, offset in ipairs({
        Vector3.new(-size.X * 0.18, 6.2, -size.Z * 0.04),
        Vector3.new(size.X * 0.18, 6.2, 0),
        Vector3.new(0, 6.2, size.Z * 0.12),
    }) do
        WorldBuilder.MakePart(folder, "HeroBlock" .. index, Vector3.new(8, 2.4, 8), CFrame.new(centerPosition + offset), kit.Accent:Lerp(kit.Primary, 0.18), accentMaterial)
    end

    for index, offset in ipairs({
        Vector3.new(-size.X * 0.35, -13, -size.Z * 0.3),
        Vector3.new(size.X * 0.35, -13, -size.Z * 0.26),
        Vector3.new(-size.X * 0.24, -14, size.Z * 0.3),
        Vector3.new(size.X * 0.24, -14, size.Z * 0.3),
        Vector3.new(0, -16, 0),
    }) do
        WorldBuilder.MakePart(folder, "SupportBlock" .. index, Vector3.new(10, 12 + index, 10), CFrame.new(centerPosition + offset), kit.Underside, sideMaterial)
    end

    for index, offset in ipairs({
        Vector3.new(-size.X * 0.46, -6, -size.Z * 0.42),
        Vector3.new(size.X * 0.46, -6, -size.Z * 0.36),
        Vector3.new(-size.X * 0.38, -7, size.Z * 0.42),
        Vector3.new(size.X * 0.38, -7, size.Z * 0.42),
    }) do
        WorldBuilder.MakePart(folder, "CornerRock" .. index, Vector3.new(8, 6, 8), CFrame.new(centerPosition + offset), kit.Rim, sideMaterial)
    end

    if options.Glow and getQualityTier().EnableIslandGlow then
        local glow = WorldBuilder.MakePart(folder, "IslandGlow", Vector3.new(size.X * 0.68, 0.5, size.Z * 0.68), CFrame.new(centerPosition + Vector3.new(0, 2.3, 0)), kit.Accent, Enum.Material.Neon, {
            CanCollide = false,
            Transparency = 0.93,
            CastShadow = false,
        })
        WorldBuilder.AddPointLight(glow, kit.Accent, 0.16, {
            Range = math.max(size.X, size.Z) * 0.18,
            Category = "PureDecor",
        })
    end

    return folder
end

function WorldBuilder.BuildRouteMarkers(parent, fromPosition, toPosition, color)
    local delta = toPosition - fromPosition
    local markerCount = isLowTier() and 3 or 5
    for index = 1, markerCount do
        local alpha = index / (markerCount + 1)
        local position = fromPosition + (delta * alpha) + Vector3.new(0, 0.24, 0)
        WorldBuilder.MakePart(parent, "RouteMarker" .. index, Vector3.new(4, 1, 4), CFrame.new(position), color:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.SmoothPlastic, {
            CanCollide = false,
            Transparency = isLowTier() and 0.32 or 0.2,
            CastShadow = false,
        })
    end
end

function WorldBuilder.BuildRouteMouth(parent, name, cframe, color, labelText)
    local folder = WorldBuilder.MakeFolder(parent, name)
    WorldBuilder.MakePart(folder, "Apron", Vector3.new(22, 1.6, 14), cframe * CFrame.new(0, 0.5, 0), color:Lerp(Color3.new(0, 0, 0), 0.24), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "Lip", Vector3.new(18, 1.4, 5), cframe * CFrame.new(0, 1.4, -4.6), color:Lerp(Color3.new(1, 1, 1), 0.1), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "RailLeft", Vector3.new(1.8, 3.4, 14), cframe * CFrame.new(-10.2, 2.1, 0), color:Lerp(Color3.new(0, 0, 0), 0.28), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "RailRight", Vector3.new(1.8, 3.4, 14), cframe * CFrame.new(10.2, 2.1, 0), color:Lerp(Color3.new(0, 0, 0), 0.28), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "PostLeft", Vector3.new(2.4, 10, 2.4), cframe * CFrame.new(-8.2, 5.0, 1.2), color:Lerp(Color3.new(0, 0, 0), 0.34), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "PostRight", Vector3.new(2.4, 10, 2.4), cframe * CFrame.new(8.2, 5.0, 1.2), color:Lerp(Color3.new(0, 0, 0), 0.34), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "Crossbeam", Vector3.new(16.8, 2.2, 2.2), cframe * CFrame.new(0, 9.2, 1), color:Lerp(Color3.new(1, 1, 1), 0.05), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "BlockStepLeft", Vector3.new(4.8, 2.2, 4.8), cframe * CFrame.new(-5.8, 1.3, 4.8), color:Lerp(Color3.new(0, 0, 0), 0.16), Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "BlockStepRight", Vector3.new(4.8, 2.2, 4.8), cframe * CFrame.new(5.8, 1.3, 4.8), color:Lerp(Color3.new(0, 0, 0), 0.16), Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "ArrowStem", Vector3.new(3.2, 0.8, 7), cframe * CFrame.new(0, 1.8, -0.8), color:Lerp(Color3.new(1, 1, 1), 0.16), Enum.Material.WoodPlanks, {
        CanCollide = false,
    })
    WorldBuilder.MakePart(folder, "ArrowHead", Vector3.new(6.6, 0.8, 6.6), cframe * CFrame.new(0, 1.8, -4.8), color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.WoodPlanks, {
        CanCollide = false,
    })
    local sign = WorldBuilder.MakePart(folder, "Sign", Vector3.new(7.6, 2.2, 0.8), cframe * CFrame.new(0, 6.1, 2.2), Color3.fromRGB(24, 30, 43), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(sign, labelText, VisualKit.Global.TextLight, 18)
    return folder
end

function WorldBuilder.BuildEmeraldShrine(parent, name, cframe, color, labelText)
    local folder = WorldBuilder.MakeFolder(parent, name)
    WorldBuilder.MakePart(folder, "ShrineBase", Vector3.new(22, 5, 22), cframe * CFrame.new(0, -1, 0), Color3.fromRGB(66, 70, 76), Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "ShrineTrim", Vector3.new(14, 3, 14), cframe * CFrame.new(0, 2.4, 0), color:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.Slate)
    WorldBuilder.MakePart(folder, "EmeraldPedestal", Vector3.new(7, 7, 7), cframe * CFrame.new(0, 5.8, 0), Color3.fromRGB(32, 40, 36), Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "PedestalCap", Vector3.new(10, 1.4, 10), cframe * CFrame.new(0, 9.8, 0), color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.Slate)
    WorldBuilder.MakePart(folder, "ShrineStepNorth", Vector3.new(12, 1.6, 4), cframe * CFrame.new(0, 1.1, -8.6), color:Lerp(Color3.new(0, 0, 0), 0.16), Enum.Material.Rock)
    WorldBuilder.MakePart(folder, "ShrineStepSouth", Vector3.new(12, 1.6, 4), cframe * CFrame.new(0, 1.1, 8.6), color:Lerp(Color3.new(0, 0, 0), 0.16), Enum.Material.Rock)
    local beacon = WorldBuilder.MakePart(folder, "Beacon", Vector3.new(5, 24, 5), cframe * CFrame.new(0, 16, 0), color, Enum.Material.Neon, {
        Transparency = isLowTier() and 0.5 or 0.28,
        CanCollide = false,
    })
    WorldBuilder.AddPointLight(beacon, color, 0.18, {
        Range = 14,
        Category = "ReadabilitySupport",
    })
    local sign = WorldBuilder.MakePart(folder, "Sign", Vector3.new(8, 2.2, 0.8), cframe * CFrame.new(0, 5.2, -12.2), Color3.fromRGB(24, 30, 43), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(sign, labelText, VisualKit.Global.TextLight, 18)
    for _, offset in ipairs({
        Vector3.new(0, 11.2, 0),
        Vector3.new(-1.8, 10.2, 0),
        Vector3.new(1.8, 10.2, 0),
        Vector3.new(0, 9.2, 0),
    }) do
        WorldBuilder.MakePart(folder, "EmeraldPixel", Vector3.new(1.2, 1.2, 1.2), cframe * CFrame.new(offset), color, Enum.Material.Neon, {
            CanCollide = false,
        })
    end
    return folder
end

function WorldBuilder.BuildBridge(parent, name, fromPosition, toPosition, color, options)
    options = options or {}
    local folder = WorldBuilder.MakeFolder(parent, name)
    local delta = toPosition - fromPosition
    local distance = delta.Magnitude
    if distance <= 0.01 then
        return folder
    end

    local direction = delta.Unit
    local bridgeCFrame = CFrame.lookAt((fromPosition + toPosition) * 0.5, toPosition)
    local width = options.Width or 14
    local thickness = options.Thickness or 2.4
    local railHeight = options.RailHeight or 3.2
    local railOffset = (width * 0.5) - 1.2

    WorldBuilder.MakePart(folder, "Deck", Vector3.new(width, thickness, distance), bridgeCFrame, color, options.Material or Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "DeckTrim", Vector3.new(width - 2, 0.6, distance - 4), bridgeCFrame * CFrame.new(0, thickness * 0.5 + 0.35, 0), color:Lerp(Color3.new(1, 1, 1), 0.14), options.TrimMaterial or Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.MakePart(folder, "RailLeft", Vector3.new(1.2, railHeight, distance), bridgeCFrame * CFrame.new(-railOffset, railHeight * 0.5, 0), color:Lerp(Color3.new(0, 0, 0), 0.26), Enum.Material.WoodPlanks)
    WorldBuilder.MakePart(folder, "RailRight", Vector3.new(1.2, railHeight, distance), bridgeCFrame * CFrame.new(railOffset, railHeight * 0.5, 0), color:Lerp(Color3.new(0, 0, 0), 0.26), Enum.Material.WoodPlanks)

    local plankCount = math.max(2, math.floor(distance / 12))
    for index = 1, plankCount do
        local alpha = (index - 0.5) / plankCount
        local position = fromPosition:Lerp(toPosition, alpha)
        local plankCFrame = CFrame.lookAt(position + Vector3.new(0, thickness * 0.5 + 0.55, 0), position + direction)
        WorldBuilder.MakePart(folder, "Plank" .. index, Vector3.new(width - 3.4, 0.6, 2.6), plankCFrame, color:Lerp(Color3.new(0, 0, 0), 0.18), Enum.Material.WoodPlanks, {
            CanCollide = false,
        })
    end

    for _, endpoint in ipairs({ fromPosition, toPosition }) do
        WorldBuilder.MakePart(folder, "EntryPost", Vector3.new(width - 2, 4, 2), CFrame.new(endpoint + Vector3.new(0, 2, 0)), color:Lerp(Color3.new(0, 0, 0), 0.22), Enum.Material.WoodPlanks)
    end

    local startFrame = CFrame.lookAt(fromPosition, toPosition)
    local endFrame = CFrame.lookAt(toPosition, fromPosition)
    for _, frame in ipairs({ startFrame, endFrame }) do
        WorldBuilder.MakePart(folder, "ArchLeft", Vector3.new(1.6, 7, 1.6), frame * CFrame.new(-(width * 0.5) + 1.8, 3.5, 0), color:Lerp(Color3.new(0, 0, 0), 0.34), Enum.Material.WoodPlanks)
        WorldBuilder.MakePart(folder, "ArchRight", Vector3.new(1.6, 7, 1.6), frame * CFrame.new((width * 0.5) - 1.8, 3.5, 0), color:Lerp(Color3.new(0, 0, 0), 0.34), Enum.Material.WoodPlanks)
        WorldBuilder.MakePart(folder, "ArchTop", Vector3.new(width - 2.6, 1.4, 1.6), frame * CFrame.new(0, 7, 0), color:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.WoodPlanks)
    end

    return folder
end

function WorldBuilder.BuildGenerator(parent, name, cframe, color, resourceName)
    local pad = WorldBuilder.MakePart(parent, name .. "Pad", Vector3.new(10, 1.4, 10), cframe * CFrame.new(0, 0.1, 0), color:Lerp(Color3.new(0, 0, 0), 0.42), Enum.Material.Rock)
    WorldBuilder.MakePart(parent, name .. "Trim", Vector3.new(8, 0.8, 8), cframe * CFrame.new(0, 1.1, 0), color:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.Slate)
    local generatorMaterial = (resourceName == "Esmeralda" and getQualityTier().EnableLargeNeon) and Enum.Material.Neon or Enum.Material.SmoothPlastic
    local generator = WorldBuilder.MakePart(parent, name, Vector3.new(4, 2.4, 4), cframe * CFrame.new(0, 2.2, 0), color, generatorMaterial, {
        Transparency = resourceName == "Esmeralda" and (isLowTier() and 0.28 or 0.18) or 0.08,
    })
    local sign = WorldBuilder.MakePart(parent, name .. "Sign", Vector3.new(8, 2.4, 0.8), cframe * CFrame.new(0, 4.1, -5.2), Color3.fromRGB(24, 30, 43), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(sign, resourceName, VisualKit.Global.TextLight, 24)
    WorldBuilder.AddPointLight(generator, color, resourceName == "Esmeralda" and 0.22 or 0.14, {
        Range = resourceName == "Esmeralda" and 10 or 8,
        Category = "PureDecor",
    })
    WorldBuilder.AddParticles(generator, color, resourceName == "Esmeralda" and 0.8 or 0.45, 1, {
        Category = "PureDecor",
    })
    pad:SetAttribute("GameplayDecor", true)
    sign:SetAttribute("GameplayDecor", true)
    return generator
end

function WorldBuilder.BuildShopStand(parent, name, cframe, color, title)
    local stand = WorldBuilder.MakePart(parent, name, Vector3.new(10, 8, 8), cframe, color:Lerp(Color3.new(0, 0, 0), 0.18), Enum.Material.WoodPlanks)
    local counter = WorldBuilder.MakePart(parent, name .. "Counter", Vector3.new(12, 2, 6), cframe * CFrame.new(0, -3, -4.8), color:Lerp(Color3.new(0, 0, 0), 0.4), Enum.Material.Rock)
    local roof = WorldBuilder.MakePart(parent, name .. "Roof", Vector3.new(14, 1.6, 10), cframe * CFrame.new(0, 4.8, 0), color:Lerp(Color3.new(1, 1, 1), 0.1), Enum.Material.WoodPlanks)
    local postLeft = WorldBuilder.MakePart(parent, name .. "PostLeft", Vector3.new(1.6, 8.4, 1.6), cframe * CFrame.new(-4.2, 0, -2.6), color:Lerp(Color3.new(0, 0, 0), 0.32), Enum.Material.Wood)
    local postRight = WorldBuilder.MakePart(parent, name .. "PostRight", Vector3.new(1.6, 8.4, 1.6), cframe * CFrame.new(4.2, 0, -2.6), color:Lerp(Color3.new(0, 0, 0), 0.32), Enum.Material.Wood)
    local sign = WorldBuilder.MakePart(parent, name .. "Sign", Vector3.new(9, 2.8, 0.8), cframe * CFrame.new(0, 2.8, -4.5), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(sign, title, VisualKit.Global.TextLight, 24)
    WorldBuilder.AddPointLight(roof, color, 0.14, {
        Range = 10,
        Category = "PureDecor",
    })
    counter:SetAttribute("GameplayDecor", true)
    roof:SetAttribute("GameplayDecor", true)
    postLeft:SetAttribute("GameplayDecor", true)
    postRight:SetAttribute("GameplayDecor", true)
    sign:SetAttribute("GameplayDecor", true)
    return stand
end

local TotemPatterns = {
    planicie = {
        "001100",
        "011110",
        "111111",
        "111111",
        "011110",
        "001100",
    },
    deserto = {
        "001100",
        "011110",
        "111111",
        "111111",
        "011110",
        "001100",
    },
    taiga = {
        "001100",
        "011110",
        "111111",
        "001100",
        "001100",
        "011110",
    },
    selva = {
        "001100",
        "011110",
        "111111",
        "111111",
        "011110",
        "010010",
    },
    neve = {
        "100001",
        "010010",
        "001100",
        "001100",
        "010010",
        "100001",
    },
    cogumelos = {
        "011110",
        "111111",
        "111111",
        "011110",
        "001100",
        "001100",
    },
}

local function addFlagPattern(parent, centerCFrame, primaryColor, secondaryColor, pattern)
    local cellSize = 1.05
    local startX = -((#pattern[1] - 1) * cellSize * 0.5)
    local startY = ((#pattern - 1) * cellSize * 0.5)

    for rowIndex, row in ipairs(pattern) do
        for columnIndex = 1, #row do
            if row:sub(columnIndex, columnIndex) == "1" then
                local x = startX + ((columnIndex - 1) * cellSize)
                local y = startY - ((rowIndex - 1) * cellSize)
                local pixelFrame = centerCFrame * CFrame.new(x, y, -0.46)
                WorldBuilder.MakePart(parent, "FlagPixelFront", Vector3.new(0.9, 0.9, 0.2), pixelFrame, primaryColor, Enum.Material.SmoothPlastic, {
                    CanCollide = false,
                })
                WorldBuilder.MakePart(parent, "FlagPixelBack", Vector3.new(0.9, 0.9, 0.2), centerCFrame * CFrame.new(x, y, 0.46), secondaryColor, Enum.Material.SmoothPlastic, {
                    CanCollide = false,
                })
            end
        end
    end
end

function WorldBuilder.BuildCore(parent, cframe, color, biomeId, labelText)
    local kit = VisualKit.Biomes[biomeId] or VisualKit.Biomes.planicie
    local pedestal = WorldBuilder.MakePart(parent, "CorePedestal", Vector3.new(18, 3.4, 18), cframe * CFrame.new(0, -3.8, 0), color:Lerp(Color3.new(0, 0, 0), 0.42), Enum.Material.Rock)
    local pedestalStep = WorldBuilder.MakePart(parent, "CorePedestalStep", Vector3.new(14, 1.6, 14), cframe * CFrame.new(0, -1.2, 0), color:Lerp(Color3.new(0, 0, 0), 0.22), Enum.Material.Slate)
    local upperPedestal = WorldBuilder.MakePart(parent, "CorePedestalUpper", Vector3.new(10, 2, 10), cframe * CFrame.new(0, 0.2, 0), color:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.SmoothPlastic)
    local auraMaterial = getQualityTier().EnableLargeNeon and Enum.Material.Neon or Enum.Material.SmoothPlastic
    local aura = WorldBuilder.MakePart(parent, "CoreAura", Vector3.new(10, 0.4, 10), cframe * CFrame.new(0, -0.2, 0), color, auraMaterial, {
        CanCollide = false,
        Transparency = isLowTier() and 0.86 or 0.76,
        CastShadow = false,
    })
    local totemBase = WorldBuilder.MakePart(parent, "TotemBase", Vector3.new(8, 2.4, 8), cframe * CFrame.new(0, 1.2, 0), Color3.fromRGB(88, 62, 45), Enum.Material.WoodPlanks)
    local pole = WorldBuilder.MakePart(parent, "TotemPole", Vector3.new(2, 14, 2), cframe * CFrame.new(0, 8, 0), color:Lerp(Color3.new(0, 0, 0), 0.24), Enum.Material.WoodPlanks)
    local crossbar = WorldBuilder.MakePart(parent, "TotemCrossbar", Vector3.new(12, 1.4, 1.4), cframe * CFrame.new(0, 12.4, 0), color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.WoodPlanks)
    local flagPlate = WorldBuilder.MakePart(parent, "TotemFlag", Vector3.new(10, 10, 0.8), cframe * CFrame.new(0, 7.4, -1.2), kit.Secondary, Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    local crest = WorldBuilder.MakePart(parent, "TotemCrest", Vector3.new(3.4, 3.4, 3.4), cframe * CFrame.new(0, 15.8, 0), kit.Accent, Enum.Material.SmoothPlastic)
    local core = WorldBuilder.MakePart(parent, "Core", Vector3.new(9, 14, 5), cframe * CFrame.new(0, 7.4, -0.8), color, Enum.Material.SmoothPlastic, {
        Transparency = 1,
        CanCollide = false,
    })
    local statusPlinth = WorldBuilder.MakePart(parent, "CoreStatusPlinth", Vector3.new(12, 3, 2), cframe * CFrame.new(0, 0.6, -10), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic)
    local statusText = string.format("Totem %d/%d", Config.Match.MaxCoreHealth, Config.Match.MaxCoreHealth)
    WorldBuilder.AddDoubleSurfaceText(statusPlinth, statusText, VisualKit.Global.TextLight, 24)
    WorldBuilder.AddBillboard(flagPlate, "CoreStatus", statusText, VisualKit.Global.TextLight, UDim2.fromOffset(210, 44), Vector3.new(0, 7.2, 0), {
        MaxDistance = 22,
        BackgroundTransparency = 0.22,
        Category = "GameplayCritical",
    })
    addFlagPattern(parent, flagPlate.CFrame, kit.Accent, color:Lerp(Color3.new(1, 1, 1), 0.06), TotemPatterns[biomeId] or TotemPatterns.planicie)
    local labelPanel = WorldBuilder.MakePart(parent, "TotemLabel", Vector3.new(9, 1.8, 0.8), cframe * CFrame.new(0, 2, -7), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(labelPanel, labelText or "Totem", VisualKit.Global.TextLight, 16)
    WorldBuilder.AddPointLight(flagPlate, color, 0.22, {
        Range = 14,
        Category = "GameplayCritical",
    })
    WorldBuilder.AddParticles(flagPlate, color, 0.8, 1.3, {
        Category = "GameplayCritical",
    })
    pedestal:SetAttribute("GameplayDecor", true)
    pedestalStep:SetAttribute("GameplayDecor", true)
    upperPedestal:SetAttribute("GameplayDecor", true)
    aura:SetAttribute("GameplayDecor", true)
    totemBase:SetAttribute("GameplayDecor", true)
    pole:SetAttribute("GameplayDecor", true)
    crossbar:SetAttribute("GameplayDecor", true)
    flagPlate:SetAttribute("GameplayDecor", true)
    crest:SetAttribute("GameplayDecor", true)
    labelPanel:SetAttribute("GameplayDecor", true)
    return core
end

local function makeFlower(parent, position, color)
    WorldBuilder.MakePart(parent, "FlowerStem", Vector3.new(0.3, 2, 0.3), CFrame.new(position + Vector3.new(0, 1, 0)), Color3.fromRGB(73, 143, 68), Enum.Material.Grass, {
        CanCollide = false,
    })
    WorldBuilder.MakePart(parent, "FlowerBloom", Vector3.new(1, 1, 1), CFrame.new(position + Vector3.new(0, 2.15, 0)), color, Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
end

local function makeTree(parent, position, trunkColor, leafColor)
    WorldBuilder.MakePart(parent, "TreeTrunk", Vector3.new(2.6, 8, 2.6), CFrame.new(position + Vector3.new(0, 4, 0)), trunkColor, Enum.Material.Wood)
    WorldBuilder.MakePart(parent, "TreeCrownLower", Vector3.new(8, 4, 8), CFrame.new(position + Vector3.new(0, 8.2, 0)), leafColor, Enum.Material.LeafyGrass)
    WorldBuilder.MakePart(parent, "TreeCrownMid", Vector3.new(6, 4, 6), CFrame.new(position + Vector3.new(0, 11.2, 0)), leafColor:Lerp(Color3.new(1, 1, 1), 0.04), Enum.Material.LeafyGrass)
    WorldBuilder.MakePart(parent, "TreeCrownTop", Vector3.new(4, 3.2, 4), CFrame.new(position + Vector3.new(0, 14, 0)), leafColor:Lerp(Color3.new(0, 0, 0), 0.05), Enum.Material.LeafyGrass)
end

local function makeCrystal(parent, position, color)
    local crystal = WorldBuilder.MakePart(parent, "Crystal", Vector3.new(4, 10, 4), CFrame.new(position + Vector3.new(0, 5, 0)), color, Enum.Material.Ice)
    crystal.Transparency = 0.1
    WorldBuilder.AddPointLight(crystal, color, 0.14, {
        Range = 9,
        Category = "PureDecor",
    })
end

local function makeMushroom(parent, position, stemColor, capColor)
    WorldBuilder.MakePart(parent, "MushroomStem", Vector3.new(3, 7, 3), CFrame.new(position + Vector3.new(0, 3.5, 0)), stemColor, Enum.Material.SmoothPlastic)
    WorldBuilder.MakePart(parent, "MushroomCapBase", Vector3.new(9, 2.2, 9), CFrame.new(position + Vector3.new(0, 7.6, 0)), capColor, Enum.Material.SmoothPlastic)
    WorldBuilder.MakePart(parent, "MushroomCapTop", Vector3.new(7, 1.6, 7), CFrame.new(position + Vector3.new(0, 9.2, 0)), capColor:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.SmoothPlastic)
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
            WorldBuilder.MakePart(parent, "FencePost", Vector3.new(1, 3, 1), CFrame.new(position + Vector3.new(2, 1.5, 2)), Color3.fromRGB(104, 78, 56), Enum.Material.WoodPlanks)
        elseif kit.PropStyle == "dunes" then
            WorldBuilder.MakePart(parent, "DuneLayerLow", Vector3.new(12, 2, 6), CFrame.new(position + Vector3.new(0, 1, 0)), kit.Primary, Enum.Material.Sand)
            WorldBuilder.MakePart(parent, "DuneLayerHigh", Vector3.new(8, 2, 4), CFrame.new(position + Vector3.new(0, 2.6, 0)), kit.Secondary, Enum.Material.Sandstone)
            WorldBuilder.MakePart(parent, "Cactus", Vector3.new(2, 7, 2), CFrame.new(position + Vector3.new(3, 3.5, -1)), Color3.fromRGB(78, 138, 65), Enum.Material.Grass)
            WorldBuilder.MakePart(parent, "SandRuin", Vector3.new(5, 5, 5), CFrame.new(position + Vector3.new(-3, 2.5, 1)), kit.Accent, Enum.Material.Sandstone)
        elseif kit.PropStyle == "pines" then
            makeTree(parent, position, Color3.fromRGB(86, 63, 44), kit.Primary:Lerp(Color3.new(0, 0, 0), 0.18))
            WorldBuilder.MakePart(parent, "Crate", Vector3.new(4, 4, 4), CFrame.new(position + Vector3.new(4, 2, 2)), Color3.fromRGB(89, 71, 54), Enum.Material.WoodPlanks)
            WorldBuilder.MakePart(parent, "StonePile", Vector3.new(6, 3, 6), CFrame.new(position + Vector3.new(-4, 1.5, -2)), kit.Rim, Enum.Material.Rock)
        elseif kit.PropStyle == "jungle" then
            makeTree(parent, position, Color3.fromRGB(82, 55, 35), kit.Secondary)
            WorldBuilder.MakePart(parent, "WoodPlatform", Vector3.new(8, 1, 8), CFrame.new(position + Vector3.new(0, 5, 0)), Color3.fromRGB(108, 82, 54), Enum.Material.WoodPlanks)
            WorldBuilder.MakePart(parent, "JungleRoot", Vector3.new(5, 4, 5), CFrame.new(position + Vector3.new(-4, 2, 3)), kit.Secondary:Lerp(Color3.new(0, 0, 0), 0.16), Enum.Material.Wood)
        elseif kit.PropStyle == "crystals" then
            makeCrystal(parent, position, kit.Accent)
            WorldBuilder.MakePart(parent, "SnowBlock", Vector3.new(5, 2, 5), CFrame.new(position + Vector3.new(3, 1, 1)), Color3.fromRGB(235, 242, 245), Enum.Material.Snow)
            WorldBuilder.MakePart(parent, "IceShelf", Vector3.new(7, 2, 5), CFrame.new(position + Vector3.new(-3, 1, -2)), kit.Secondary, Enum.Material.Ice)
        elseif kit.PropStyle == "mushrooms" then
            makeMushroom(parent, position, Color3.fromRGB(232, 214, 188), kit.Secondary)
            WorldBuilder.MakePart(parent, "MudPatch", Vector3.new(6, 1.4, 6), CFrame.new(position + Vector3.new(-2, 0.7, 2)), Color3.fromRGB(92, 64, 75), Enum.Material.Mud)
            WorldBuilder.MakePart(parent, "CapStone", Vector3.new(4, 3, 4), CFrame.new(position + Vector3.new(4, 1.5, -3)), kit.Accent, Enum.Material.Slate)
        end
    end
end

function WorldBuilder.BuildLandmark(parent, cframe, kit, labelText)
    local basePosition = cframe.Position
    if kit.Landmark == "oak" then
        makeTree(parent, basePosition + Vector3.new(0, 0, 0), Color3.fromRGB(91, 67, 45), kit.Primary:Lerp(Color3.new(0, 0, 0), 0.1))
    elseif kit.Landmark == "obelisk" then
        WorldBuilder.MakePart(parent, "LandmarkObelisk", Vector3.new(8, 28, 8), CFrame.new(basePosition + Vector3.new(0, 14, 0)), kit.Accent, Enum.Material.Sandstone)
    elseif kit.Landmark == "pine" then
        makeTree(parent, basePosition, Color3.fromRGB(76, 56, 40), kit.Secondary)
        WorldBuilder.MakePart(parent, "LandmarkSpire", Vector3.new(6, 10, 6), CFrame.new(basePosition + Vector3.new(0, 19, 0)), kit.Primary, Enum.Material.LeafyGrass)
    elseif kit.Landmark == "canopy" then
        makeTree(parent, basePosition, Color3.fromRGB(76, 54, 35), kit.Secondary)
        makeTree(parent, basePosition + Vector3.new(8, 0, -3), Color3.fromRGB(76, 54, 35), kit.Primary)
    elseif kit.Landmark == "ice" then
        makeCrystal(parent, basePosition, kit.Accent)
        makeCrystal(parent, basePosition + Vector3.new(7, 0, -5), kit.Secondary)
    elseif kit.Landmark == "mushroom" then
        makeMushroom(parent, basePosition, Color3.fromRGB(230, 214, 196), kit.Secondary)
        makeMushroom(parent, basePosition + Vector3.new(8, 0, -4), Color3.fromRGB(220, 205, 188), kit.Accent)
    end

    local banner = WorldBuilder.MakePart(parent, "BiomeBanner", Vector3.new(18, 7, 1), cframe * CFrame.new(0, 2, 0), Color3.fromRGB(21, 28, 39), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(banner, labelText, kit.Accent, 20)
end

return WorldBuilder
