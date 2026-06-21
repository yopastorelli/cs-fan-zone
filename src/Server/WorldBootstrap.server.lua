local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldData = require(Shared:WaitForChild("WorldData"))
local Remotes = require(Shared:WaitForChild("Remotes"))

Remotes.GetAll()

local WORLD_NAME = "CSFanZone"

local function clearChildren(instance)
    for _, child in ipairs(instance:GetChildren()) do
        child:Destroy()
    end
end

local function ensureWorldRoot()
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate then
        baseplate:Destroy()
    end

    local root = Workspace:FindFirstChild(WORLD_NAME)
    if not root then
        root = Instance.new("Folder")
        root.Name = WORLD_NAME
        root.Parent = Workspace
    end

    clearChildren(root)
    return root
end

local function makeFolder(parent, name)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function makePart(parent, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function addSurfaceText(part, face, text, textColor)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "SurfaceGui"
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 36
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

    return label
end

local function addBillboard(part, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Billboard"
    billboard.Size = UDim2.fromOffset(190, 56)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Config.UI.Theme.PanelColor
    label.BackgroundTransparency = 0.12
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color or Config.UI.Theme.TextColor
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
end

local function addPrompt(parent, name, actionText, objectText)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = name
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    return prompt
end

local function addLight(parent, name, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Name = name
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Parent = parent
    return light
end

local function makeZone(root, area)
    local folder = makeFolder(root, area.Name)

    makePart(
        folder,
        "Floor",
        area.Size,
        CFrame.new(area.Position + Vector3.new(0, -1, 0)),
        Color3.fromRGB(28, 34, 46),
        Enum.Material.Concrete
    )

    local sign = makePart(
        folder,
        "ZoneSign",
        Vector3.new(28, 9, 1),
        CFrame.new(area.Position + Vector3.new(0, 10, -((area.Size.Z / 2) - 8))),
        area.AccentColor,
        Enum.Material.Neon
    )
    sign.CanCollide = false
    addSurfaceText(sign, Enum.NormalId.Front, area.DisplayName, Config.UI.Theme.TextColor)

    return folder
end

local function makePath(parent, pathDef)
    local startPosition = pathDef.From
    local endPosition = pathDef.To
    local midpoint = (startPosition + endPosition) / 2
    local distance = (endPosition - startPosition).Magnitude
    local area = Config.Areas[pathDef.ColorArea]
    local color = area and area.AccentColor or Config.UI.Theme.AccentColor

    local path = makePart(
        parent,
        pathDef.Name,
        Vector3.new(10, 0.35, distance),
        CFrame.lookAt(midpoint + Vector3.new(0, 0.2, 0), endPosition),
        color,
        Enum.Material.Neon
    )
    path.Transparency = 0.45
    path.CanCollide = false
end

local function makeTree(parent, position)
    makePart(
        parent,
        "TreeTrunk",
        Vector3.new(2, 9, 2),
        CFrame.new(position + Vector3.new(0, 4.5, 0)),
        Color3.fromRGB(92, 58, 35),
        Enum.Material.Wood
    )

    local leaves = Instance.new("Part")
    leaves.Name = "TreeLeaves"
    leaves.Shape = Enum.PartType.Ball
    leaves.Size = Vector3.new(9, 9, 9)
    leaves.CFrame = CFrame.new(position + Vector3.new(0, 11, 0))
    leaves.Anchored = true
    leaves.Color = Color3.fromRGB(78, 190, 112)
    leaves.Material = Enum.Material.Grass
    leaves.Parent = parent
end

local function makeSeat(parent, name, position, color)
    makePart(parent, name .. "Base", Vector3.new(10, 2, 6), CFrame.new(position), color, Enum.Material.SmoothPlastic)
    makePart(parent, name .. "Back", Vector3.new(10, 7, 1), CFrame.new(position + Vector3.new(0, 4, 3)), color, Enum.Material.SmoothPlastic)
end

local function makeInfoPanel(parent, name, position, size, color, text)
    local panel = makePart(parent, name, size, CFrame.new(position), color, Enum.Material.Neon)
    panel.CanCollide = false
    addSurfaceText(panel, Enum.NormalId.Front, text, Config.UI.Theme.TextColor)
    return panel
end

local function makeCollectible(root, collectible)
    local folder = root:FindFirstChild(collectible.Area)
    if not folder then
        return
    end

    local part = Instance.new("Part")
    part.Name = collectible.Id
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(4, 4, 4)
    part.CFrame = CFrame.new(collectible.Position)
    part.Anchored = true
    part.Color = collectible.Color
    part.Material = Enum.Material.Neon
    part:SetAttribute("CollectibleId", collectible.Id)
    part.Parent = folder

    addLight(part, "Glow", collectible.Color, 1.8, 14)
    addBillboard(part, collectible.DisplayName, collectible.Color)
    addPrompt(part, "CollectPrompt", "Registrar", collectible.DisplayName)
end

local function makePOI(root, poi)
    local folder = root:FindFirstChild(poi.Area)
    if not folder then
        return
    end

    local panel = makePart(
        folder,
        poi.Id,
        Vector3.new(18, 12, 2),
        CFrame.new(poi.Position),
        Config.Areas[poi.Area].AccentColor,
        Enum.Material.Neon
    )
    panel:SetAttribute("PoiId", poi.Id)
    addSurfaceText(panel, Enum.NormalId.Front, poi.DisplayName .. "\n\nPressione E", Config.UI.Theme.TextColor)
    addPrompt(panel, "PoiPrompt", poi.PromptText, poi.DisplayName)
end

local function makePortalLandmark(parent, landmark)
    local frame = makePart(parent, landmark.Name, landmark.Size, CFrame.new(landmark.Position), landmark.AccentColor, Enum.Material.Neon)
    frame.CanCollide = false

    local opening = makePart(parent, landmark.Name .. "Opening", landmark.Size - Vector3.new(8, 6, 1), CFrame.new(landmark.Position), Color3.fromRGB(18, 20, 28), Enum.Material.SmoothPlastic)
    opening.CanCollide = false
    addSurfaceText(frame, Enum.NormalId.Front, landmark.Name, Config.UI.Theme.TextColor)

    makeInfoPanel(parent, landmark.Id .. "Panel", landmark.Position + Vector3.new(0, -11, 0), Vector3.new(22, 6, 1), Color3.fromRGB(36, 40, 58), landmark.Text)
end

local function makeArenaLandmark(parent, landmark)
    local base = makePart(parent, landmark.Name, landmark.Size, CFrame.new(landmark.Position), Color3.fromRGB(42, 26, 52), Enum.Material.SmoothPlastic)
    base.Shape = Enum.PartType.Cylinder
    base.Orientation = Vector3.new(0, 0, 90)

    for index = 1, 8 do
        local angle = (math.pi * 2 / 8) * index
        local towerPosition = landmark.Position + Vector3.new(math.cos(angle) * 18, 8, math.sin(angle) * 18)
        local tower = makePart(parent, string.format("ArenaTower%d", index), Vector3.new(3, 14, 3), CFrame.new(towerPosition), landmark.AccentColor, Enum.Material.Neon)
        tower.CanCollide = true
    end

    makeInfoPanel(parent, landmark.Id .. "Panel", landmark.Position + Vector3.new(0, 10, -22), Vector3.new(22, 7, 1), landmark.AccentColor, landmark.Text)
end

local function makeGalleryLandmark(parent, landmark)
    local wall = makePart(parent, landmark.Name, landmark.Size, CFrame.new(landmark.Position), Color3.fromRGB(25, 32, 44), Enum.Material.SmoothPlastic)
    addSurfaceText(wall, Enum.NormalId.Front, landmark.Name, landmark.AccentColor)
    makeInfoPanel(parent, landmark.Id .. "Panel", landmark.Position + Vector3.new(0, -8, 0), Vector3.new(22, 6, 1), Color3.fromRGB(36, 40, 58), landmark.Text)
end

local function makeLabLandmark(parent, landmark)
    local shell = makePart(parent, landmark.Name, landmark.Size, CFrame.new(landmark.Position), Color3.fromRGB(31, 46, 40), Enum.Material.Metal)
    shell.Transparency = 0.1
    makeInfoPanel(parent, landmark.Id .. "Panel", landmark.Position + Vector3.new(0, 10, -11), Vector3.new(24, 6, 1), landmark.AccentColor, landmark.Text)
end

local function makePhotoLandmark(parent, landmark)
    local frame = makePart(parent, landmark.Name, landmark.Size, CFrame.new(landmark.Position), landmark.AccentColor, Enum.Material.Neon)
    frame.CanCollide = false
    addSurfaceText(frame, Enum.NormalId.Front, landmark.Name, Config.UI.Theme.TextColor)
    makeInfoPanel(parent, landmark.Id .. "Panel", landmark.Position + Vector3.new(0, -9, 0), Vector3.new(24, 6, 1), Color3.fromRGB(45, 36, 62), landmark.Text)
end

local function makeSecretLandmark(parent, landmark)
    local chamber = makePart(parent, landmark.Name, landmark.Size, CFrame.new(landmark.Position), Color3.fromRGB(52, 40, 78), Enum.Material.SmoothPlastic)
    chamber.Transparency = 0.05

    local core = makePart(parent, "SecretCore", Vector3.new(8, 8, 8), CFrame.new(landmark.Position + Vector3.new(0, 4, 0)), landmark.AccentColor, Enum.Material.ForceField)
    core.Shape = Enum.PartType.Ball
    local light = addLight(core, "SecretLight", landmark.AccentColor, 1.5, 16)
    light.Enabled = false

    makeInfoPanel(parent, landmark.Id .. "Panel", landmark.Position + Vector3.new(0, 10, -11), Vector3.new(24, 6, 1), landmark.AccentColor, landmark.Text)
end

local function makeLandmark(root, landmark)
    local folder = root:FindFirstChild(landmark.Area)
    if not folder then
        return
    end

    if landmark.Type == "portal" then
        makePortalLandmark(folder, landmark)
    elseif landmark.Type == "arena" then
        makeArenaLandmark(folder, landmark)
    elseif landmark.Type == "gallery" then
        makeGalleryLandmark(folder, landmark)
    elseif landmark.Type == "lab" then
        makeLabLandmark(folder, landmark)
    elseif landmark.Type == "photo" then
        makePhotoLandmark(folder, landmark)
    elseif landmark.Type == "secret" then
        makeSecretLandmark(folder, landmark)
    end
end

local function makeLoreSign(root, signDef)
    local folder = root:FindFirstChild(signDef.Area)
    if not folder then
        return
    end

    local sign = makePart(folder, signDef.Id, Vector3.new(12, 8, 1), CFrame.new(signDef.Position), Color3.fromRGB(36, 40, 58), Enum.Material.SmoothPlastic)
    sign.CanCollide = false
    addSurfaceText(sign, Enum.NormalId.Front, signDef.Text, Config.UI.Theme.TextColor)
end

local function makeArchetype(root, archetype)
    local folder = root:FindFirstChild(archetype.Area)
    if not folder then
        return
    end

    local base = makePart(folder, archetype.Id .. "Base", Vector3.new(6, 2, 6), CFrame.new(archetype.Position), archetype.Color, Enum.Material.SmoothPlastic)
    local totem = makePart(folder, archetype.Id, Vector3.new(4, 10, 4), CFrame.new(archetype.Position + Vector3.new(0, 6, 0)), archetype.Color, Enum.Material.Neon)
    totem.Shape = Enum.PartType.Cylinder
    totem.Orientation = Vector3.new(0, 0, 90)
    base.CanCollide = true
    addBillboard(totem, archetype.Name .. "\n" .. archetype.Text, archetype.Color)
end

local function makePrankPuzzle(root)
    local folder = root:FindFirstChild("MemeLounge")
    if not folder then
        return
    end

    local data = WorldData.PrankPuzzle
    for _, switchDef in ipairs(data.Switches) do
        local switch = makePart(folder, switchDef.Id, Vector3.new(4, 2, 4), CFrame.new(switchDef.Position), switchDef.Color, Enum.Material.Neon)
        switch.CanCollide = true
        addBillboard(switch, "Alavanca falsa", switchDef.Color)
    end

    local safePlatform = makePart(folder, "SafePlatform", Vector3.new(10, 1, 10), CFrame.new(data.SafePlatformPosition), Config.UI.Theme.AccentColor, Enum.Material.Metal)
    addBillboard(safePlatform, "Piso certo", Config.UI.Theme.AccentColor)

    for index, position in ipairs(data.FakePlatformPositions) do
        local fake = makePart(folder, string.format("FakePlatform%d", index), Vector3.new(10, 1, 10), CFrame.new(position), Color3.fromRGB(72, 72, 72), Enum.Material.Metal)
        fake.Transparency = 0.25
        addBillboard(fake, "Parece certo", Config.UI.Theme.WarningColor)
    end
end

local function makePhotoSpot(root)
    local folder = root:FindFirstChild("FinalCelebrationRoom")
    if not folder then
        return
    end

    local data = WorldData.PhotoSpot
    local spot = makePart(folder, data.Name, data.Size, CFrame.new(data.Position), Color3.fromRGB(70, 58, 98), Enum.Material.SmoothPlastic)
    addBillboard(spot, data.Message, Config.Areas.FinalCelebrationRoom.AccentColor)
end

local worldRoot = ensureWorldRoot()

for _, areaName in ipairs(WorldData.AreasInOrder) do
    makeZone(worldRoot, Config.Areas[areaName])
end

local centralFolder = worldRoot:FindFirstChild("CentralPlaza")
for _, pathDef in ipairs(WorldData.Paths) do
    makePath(centralFolder, pathDef)
end

local center = Config.Areas.CentralPlaza.Position
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.CFrame = CFrame.new(center + Vector3.new(0, 1, 0))
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = Config.Areas.CentralPlaza.AccentColor
spawn.Material = Enum.Material.Neon
spawn.Parent = centralFolder

local titleSign = makePart(
    centralFolder,
    "MainObjectiveSign",
    Vector3.new(38, 12, 1),
    CFrame.new(center + Vector3.new(0, 13, -30)),
    Config.Areas.CentralPlaza.AccentColor,
    Enum.Material.Neon
)
titleSign.CanCollide = false
addSurfaceText(titleSign, Enum.NormalId.Front, "CS Fan Zone\n" .. Config.Mission.ObjectiveText, Config.UI.Theme.TextColor)

for _, offset in ipairs({
    Vector3.new(-34, 0, -34),
    Vector3.new(34, 0, -34),
    Vector3.new(-34, 0, 34),
    Vector3.new(34, 0, 34),
}) do
    makeTree(centralFolder, center + offset)
end

makeSeat(worldRoot.MemeLounge, "LeftCouch", Config.Areas.MemeLounge.Position + Vector3.new(-18, 1, 18), Color3.fromRGB(45, 72, 54))
makeSeat(worldRoot.MemeLounge, "RightCouch", Config.Areas.MemeLounge.Position + Vector3.new(18, 1, 18), Color3.fromRGB(45, 72, 54))

for _, landmark in ipairs(WorldData.Landmarks) do
    makeLandmark(worldRoot, landmark)
end

for _, signDef in ipairs(WorldData.LoreSigns) do
    makeLoreSign(worldRoot, signDef)
end

for _, archetype in ipairs(WorldData.Archetypes) do
    makeArchetype(worldRoot, archetype)
end

makePrankPuzzle(worldRoot)
makePhotoSpot(worldRoot)

local finalGate = makePart(
    worldRoot.FinalCelebrationRoom,
    "FinalGate",
    Vector3.new(Config.Areas.FinalCelebrationRoom.Size.X + 20, 18, 2),
    CFrame.new(Config.Areas.FinalCelebrationRoom.Position + Vector3.new(0, 8, 28)),
    Color3.fromRGB(80, 70, 120),
    Enum.Material.ForceField
)
finalGate.Transparency = 0.25
finalGate.CanCollide = true
finalGate:SetAttribute("RequiresMissionComplete", true)
addSurfaceText(finalGate, Enum.NormalId.Front, "Sala Final\nComplete a missao para entrar", Config.UI.Theme.TextColor)
addPrompt(finalGate, "FinalGatePrompt", Config.Mission.FinalRoomPromptText, "Sala Final")

for index = 1, 12 do
    local angle = (math.pi * 2 / 12) * index
    local burst = Instance.new("Part")
    burst.Name = "CelebrationBurst" .. index
    burst.Shape = Enum.PartType.Ball
    burst.Size = Vector3.new(2, 2, 2)
    burst.CFrame = CFrame.new(Config.Areas.FinalCelebrationRoom.Position + Vector3.new(math.cos(angle) * 20, 10 + (index % 4), math.sin(angle) * 16))
    burst.Anchored = true
    burst.Color = Config.Areas.FinalCelebrationRoom.AccentColor
    burst.Material = Enum.Material.Neon
    burst.Parent = worldRoot.FinalCelebrationRoom
end

for _, collectible in ipairs(Config.Collectibles) do
    makeCollectible(worldRoot, collectible)
end

for _, poi in ipairs(Config.POIs) do
    makePOI(worldRoot, poi)
end
