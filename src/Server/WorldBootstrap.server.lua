local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
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
    gui.PixelsPerStud = 38
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
    billboard.Size = UDim2.fromOffset(170, 48)
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

local function makePath(parent, startPosition, endPosition, color)
    local midpoint = (startPosition + endPosition) / 2
    local distance = (endPosition - startPosition).Magnitude
    local path = makePart(
        parent,
        "Path",
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

    local light = Instance.new("PointLight")
    light.Name = "Glow"
    light.Color = collectible.Color
    light.Brightness = 1.8
    light.Range = 14
    light.Parent = part

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

local worldRoot = ensureWorldRoot()

for _, areaName in ipairs({
    "CentralPlaza",
    "NostalgiaWall",
    "ClipStage",
    "MemeLounge",
    "FinalCelebrationRoom",
}) do
    makeZone(worldRoot, Config.Areas[areaName])
end

local center = Config.Areas.CentralPlaza.Position
makePath(worldRoot.CentralPlaza, center + Vector3.new(-45, 0, 0), Config.Areas.NostalgiaWall.Position + Vector3.new(34, 0, 0), Config.Areas.NostalgiaWall.AccentColor)
makePath(worldRoot.CentralPlaza, center + Vector3.new(0, 0, 45), Config.Areas.ClipStage.Position + Vector3.new(0, 0, -34), Config.Areas.ClipStage.AccentColor)
makePath(worldRoot.CentralPlaza, center + Vector3.new(45, 0, 0), Config.Areas.MemeLounge.Position + Vector3.new(-34, 0, 0), Config.Areas.MemeLounge.AccentColor)
makePath(worldRoot.CentralPlaza, center + Vector3.new(0, 0, -45), Config.Areas.FinalCelebrationRoom.Position + Vector3.new(0, 0, 30), Config.Areas.FinalCelebrationRoom.AccentColor)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.CFrame = CFrame.new(center + Vector3.new(0, 1, 0))
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = Config.Areas.CentralPlaza.AccentColor
spawn.Material = Enum.Material.Neon
spawn.Parent = worldRoot.CentralPlaza

local titleSign = makePart(
    worldRoot.CentralPlaza,
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
    makeTree(worldRoot.CentralPlaza, center + offset)
end

for index = 1, 5 do
    local panel = makePart(
        worldRoot.NostalgiaWall,
        "MemoryPanel" .. index,
        Vector3.new(10, 10, 1),
        CFrame.new(Config.Areas.NostalgiaWall.Position + Vector3.new(-30 + (index * 10), 6, -30)),
        Color3.fromRGB(48, 38, 62),
        Enum.Material.SmoothPlastic
    )
    addSurfaceText(panel, Enum.NormalId.Front, "Historia\noriginal\n#" .. index, Config.Areas.NostalgiaWall.AccentColor)
end

local stageBase = makePart(
    worldRoot.ClipStage,
    "StageBase",
    Vector3.new(50, 6, 24),
    CFrame.new(Config.Areas.ClipStage.Position + Vector3.new(0, 3, 18)),
    Color3.fromRGB(44, 28, 50),
    Enum.Material.SmoothPlastic
)
stageBase.CanCollide = true

for _, x in ipairs({ -24, -8, 8, 24 }) do
    local lightTower = makePart(
        worldRoot.ClipStage,
        "StageLight",
        Vector3.new(3, 20, 3),
        CFrame.new(Config.Areas.ClipStage.Position + Vector3.new(x, 10, -20)),
        Config.Areas.ClipStage.AccentColor,
        Enum.Material.Neon
    )
    lightTower.CanCollide = true
end

makeSeat(worldRoot.MemeLounge, "LeftCouch", Config.Areas.MemeLounge.Position + Vector3.new(-18, 1, 18), Color3.fromRGB(45, 72, 54))
makeSeat(worldRoot.MemeLounge, "RightCouch", Config.Areas.MemeLounge.Position + Vector3.new(18, 1, 18), Color3.fromRGB(45, 72, 54))

for index = 1, 4 do
    local cube = makePart(
        worldRoot.MemeLounge,
        "OriginalMemeCube" .. index,
        Vector3.new(7, 7, 7),
        CFrame.new(Config.Areas.MemeLounge.Position + Vector3.new(-24 + (index * 12), 4, -6)),
        Color3.fromRGB(70, 130 + (index * 20), 110),
        Enum.Material.Neon
    )
    cube.CanCollide = true
end

local finalGate = makePart(
    worldRoot.FinalCelebrationRoom,
    "FinalGate",
    Vector3.new(36, 18, 2),
    CFrame.new(Config.Areas.FinalCelebrationRoom.Position + Vector3.new(0, 8, 28)),
    Color3.fromRGB(80, 70, 120),
    Enum.Material.ForceField
)
finalGate.Transparency = 0.25
finalGate.CanCollide = true
finalGate:SetAttribute("Unlocked", false)
addSurfaceText(finalGate, Enum.NormalId.Front, "Sala Final\nBloqueada", Config.UI.Theme.TextColor)

local celebrationSign = makePart(
    worldRoot.FinalCelebrationRoom,
    "CelebrationSign",
    Vector3.new(36, 12, 1),
    CFrame.new(Config.Areas.FinalCelebrationRoom.Position + Vector3.new(0, 12, -18)),
    Config.Areas.FinalCelebrationRoom.AccentColor,
    Enum.Material.Neon
)
celebrationSign.CanCollide = false
addSurfaceText(celebrationSign, Enum.NormalId.Front, "Celebracao final\nVoce completou o circuito!", Config.UI.Theme.TextColor)

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
