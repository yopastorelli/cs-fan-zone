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
    local root = Workspace:FindFirstChild(WORLD_NAME)
    if not root then
        root = Instance.new("Folder")
        root.Name = WORLD_NAME
        root.Parent = Workspace
    end

    clearChildren(root)
    return root
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

local function makeLabelPart(parent, name, size, cframe, surface, text, textColor, backgroundColor)
    local part = makePart(parent, name, size, cframe, backgroundColor, Enum.Material.Neon)
    part.CanCollide = false

    local gui = Instance.new("SurfaceGui")
    gui.Name = "SurfaceGui"
    gui.Face = surface
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "TextLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = textColor
    label.Parent = gui

    return part, label
end

local function makeTree(parent, position)
    local trunk = makePart(
        parent,
        "TreeTrunk",
        Vector3.new(2, 12, 2),
        CFrame.new(position + Vector3.new(0, 6, 0)),
        Color3.fromRGB(99, 62, 34),
        Enum.Material.Wood
    )
    trunk.CanCollide = true

    for _, offset in ipairs({
        Vector3.new(0, 14, 0),
        Vector3.new(4, 12, 0),
        Vector3.new(-4, 12, 0),
        Vector3.new(0, 12, 4),
    }) do
        local leaf = Instance.new("Part")
        leaf.Name = "Leaf"
        leaf.Shape = Enum.PartType.Ball
        leaf.Size = Vector3.new(7, 7, 7)
        leaf.CFrame = CFrame.new(position + offset)
        leaf.Anchored = true
        leaf.Color = Color3.fromRGB(60, 178, 93)
        leaf.Material = Enum.Material.Grass
        leaf.Parent = parent
    end
end

local function getSortedShopItemNames()
    local names = {}
    for itemName in pairs(Config.ShopItems) do
        names[#names + 1] = itemName
    end

    table.sort(names)
    return names
end

local worldRoot = ensureWorldRoot()

local hubFolder = Instance.new("Folder")
hubFolder.Name = Config.Areas.Hub.Name
hubFolder.Parent = worldRoot

local hubFloor = makePart(
    hubFolder,
    "HubFloor",
    Vector3.new(90, 2, 90),
    CFrame.new(Config.Areas.Hub.Position + Vector3.new(0, -1, 0)),
    Color3.fromRGB(24, 34, 56),
    Enum.Material.Concrete
)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(Config.Areas.Hub.Position + Vector3.new(0, 1, 0))
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = Config.Areas.Hub.AccentColor
spawn.Material = Enum.Material.Neon
spawn.Parent = hubFolder

makeLabelPart(
    hubFolder,
    "HubSign",
    Vector3.new(30, 10, 1),
    CFrame.new(Config.Areas.Hub.Position + Vector3.new(0, 12, -25)),
    Enum.NormalId.Front,
    "CS Fan Zone",
    Config.UI.Theme.TextColor,
    Config.Areas.Hub.AccentColor
)

local lounge = makePart(
    hubFolder,
    "SocialLounge",
    Vector3.new(22, 1, 16),
    CFrame.new(Config.Areas.Hub.Position + Vector3.new(0, 0.5, 24)),
    Color3.fromRGB(34, 46, 74),
    Enum.Material.SmoothPlastic
)
    lounge.CanCollide = true

for _, offset in ipairs({
    Vector3.new(26, 0, 26),
    Vector3.new(-26, 0, 26),
    Vector3.new(26, 0, -26),
    Vector3.new(-26, 0, -26),
}) do
    makeTree(hubFolder, Config.Areas.Hub.Position + offset)
end

local portalsFolder = Instance.new("Folder")
portalsFolder.Name = Config.Areas.Portals.Name
portalsFolder.Parent = worldRoot

local portalDefinitions = {
    { Name = "Arena", Position = Vector3.new(0, 5, 38), Color = Config.Areas.Arena.AccentColor },
    { Name = "Parkour", Position = Vector3.new(-38, 5, 0), Color = Config.Areas.Parkour.AccentColor },
    { Name = "Shop", Position = Vector3.new(38, 5, 0), Color = Config.Areas.Shop.AccentColor },
    { Name = "Leaderboard", Position = Vector3.new(0, 5, -38), Color = Config.Areas.Leaderboard.AccentColor },
}

for _, definition in ipairs(portalDefinitions) do
    local portal = makePart(
        portalsFolder,
        definition.Name .. "Portal",
        Vector3.new(10, 12, 2),
        CFrame.new(definition.Position),
        definition.Color,
        Enum.Material.Neon
    )
    portal.Transparency = 0.15
    portal.CanCollide = false
    portal:SetAttribute("TargetArea", definition.Name)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PortalPrompt"
    prompt.ActionText = "Viajar"
    prompt.ObjectText = definition.Name
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = portal

    local tag = Instance.new("BillboardGui")
    tag.Name = "PortalBillboard"
    tag.Size = UDim2.fromOffset(180, 50)
    tag.StudsOffset = Vector3.new(0, 8, 0)
    tag.AlwaysOnTop = true
    tag.Parent = portal

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 0.2
    textLabel.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    textLabel.Text = definition.Name
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Config.UI.Theme.TextColor
    textLabel.Parent = tag
end

local arenaFolder = Instance.new("Folder")
arenaFolder.Name = Config.Areas.Arena.Name
arenaFolder.Parent = worldRoot

makePart(
    arenaFolder,
    "ArenaFloor",
    Vector3.new(70, 2, 70),
    CFrame.new(Config.Areas.Arena.Position + Vector3.new(0, -1, 0)),
    Color3.fromRGB(54, 44, 24),
    Enum.Material.Slate
)

local arenaRing = makePart(
    arenaFolder,
    "ArenaRing",
    Vector3.new(76, 6, 76),
    CFrame.new(Config.Areas.Arena.Position + Vector3.new(0, 2, 0)),
    Config.Areas.Arena.AccentColor,
    Enum.Material.ForceField
)
arenaRing.Shape = Enum.PartType.Cylinder
arenaRing.Orientation = Vector3.new(0, 0, 90)
arenaRing.Transparency = 0.75
arenaRing.CanCollide = false

local arenaSpawn = makePart(
    arenaFolder,
    "Spawn",
    Vector3.new(8, 1, 8),
    CFrame.new(Config.Areas.Arena.Position + Vector3.new(0, 1, 0)),
    Config.Areas.Arena.AccentColor,
    Enum.Material.Neon
)
arenaSpawn.Transparency = 1
arenaSpawn.CanCollide = false

local coinCenter = makePart(
    arenaFolder,
    "CoinCenter",
    Vector3.new(2, 2, 2),
    CFrame.new(Config.Areas.Arena.Position + Vector3.new(0, Config.Coin.Height, 0)),
    Config.Coin.Color,
    Enum.Material.Neon
)
coinCenter.Transparency = 1
coinCenter.CanCollide = false

makeLabelPart(
    arenaFolder,
    "ArenaSign",
    Vector3.new(20, 8, 1),
    CFrame.new(Config.Areas.Arena.Position + Vector3.new(0, 10, -20)),
    Enum.NormalId.Front,
    "Coleta de moedas",
    Config.UI.Theme.TextColor,
    Config.Areas.Arena.AccentColor
)

local parkourFolder = Instance.new("Folder")
parkourFolder.Name = Config.Areas.Parkour.Name
parkourFolder.Parent = worldRoot

makePart(
    parkourFolder,
    "ParkourBase",
    Vector3.new(24, 2, 60),
    CFrame.new(Config.Areas.Parkour.Position + Vector3.new(0, -1, 0)),
    Color3.fromRGB(25, 40, 25),
    Enum.Material.Grass
)

local parkourSpawn = makePart(
    parkourFolder,
    "Spawn",
    Vector3.new(8, 1, 8),
    CFrame.new(Config.Areas.Parkour.Position + Vector3.new(0, 1, -24)),
    Config.Areas.Parkour.AccentColor,
    Enum.Material.Neon
)
parkourSpawn.Transparency = 1
parkourSpawn.CanCollide = false

for stepIndex = 1, 8 do
    local xOffset = (stepIndex % 2 == 0) and 6 or -6
    makePart(
        parkourFolder,
        "Step" .. stepIndex,
        Vector3.new(8, 2, 8),
        CFrame.new(Config.Areas.Parkour.Position + Vector3.new(xOffset, 2 + stepIndex, -18 + (stepIndex * 8))),
        Config.Areas.Parkour.AccentColor,
        Enum.Material.Neon
    )
end

makeLabelPart(
    parkourFolder,
    "ParkourSign",
    Vector3.new(18, 7, 1),
    CFrame.new(Config.Areas.Parkour.Position + Vector3.new(0, 12, -28)),
    Enum.NormalId.Front,
    "Desafio Parkour",
    Config.UI.Theme.TextColor,
    Config.Areas.Parkour.AccentColor
)

local shopFolder = Instance.new("Folder")
shopFolder.Name = Config.Areas.Shop.Name
shopFolder.Parent = worldRoot

makePart(
    shopFolder,
    "ShopFloor",
    Vector3.new(42, 2, 42),
    CFrame.new(Config.Areas.Shop.Position + Vector3.new(0, -1, 0)),
    Color3.fromRGB(40, 24, 40),
    Enum.Material.Marble
)

local shopSpawn = makePart(
    shopFolder,
    "Spawn",
    Vector3.new(8, 1, 8),
    CFrame.new(Config.Areas.Shop.Position + Vector3.new(0, 1, 14)),
    Config.Areas.Shop.AccentColor,
    Enum.Material.Neon
)
shopSpawn.Transparency = 1
shopSpawn.CanCollide = false

makeLabelPart(
    shopFolder,
    "ShopSign",
    Vector3.new(18, 7, 1),
    CFrame.new(Config.Areas.Shop.Position + Vector3.new(0, 12, -12)),
    Enum.NormalId.Front,
    "Loja Cosmetica",
    Config.UI.Theme.TextColor,
    Config.Areas.Shop.AccentColor
)

local kiosk = makePart(
    shopFolder,
    "Kiosk",
    Vector3.new(24, 10, 10),
    CFrame.new(Config.Areas.Shop.Position + Vector3.new(0, 5, -2)),
    Color3.fromRGB(62, 35, 65),
    Enum.Material.SmoothPlastic
)
kiosk.CanCollide = true

local itemIndex = 0
for _, itemName in ipairs(getSortedShopItemNames()) do
    local item = Config.ShopItems[itemName]
    itemIndex += 1
    local standOffset = -10 + (itemIndex * 10)
    local stand = makePart(
        shopFolder,
        itemName .. "Stand",
        Vector3.new(6, 6, 6),
        CFrame.new(Config.Areas.Shop.Position + Vector3.new(standOffset, 3, 10)),
        item.TintColor,
        Enum.Material.Neon
    )
    stand.CanCollide = true

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ItemBillboard"
    billboard.Size = UDim2.fromOffset(180, 60)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = stand

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    label.BackgroundTransparency = 0.2
    label.Text = string.format("%s\n%d coins", item.DisplayName, item.Price)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Config.UI.Theme.TextColor
    label.Parent = billboard
end

local leaderboardFolder = Instance.new("Folder")
leaderboardFolder.Name = Config.Areas.Leaderboard.Name
leaderboardFolder.Parent = worldRoot

makePart(
    leaderboardFolder,
    "LeaderboardFloor",
    Vector3.new(38, 2, 38),
    CFrame.new(Config.Areas.Leaderboard.Position + Vector3.new(0, -1, 0)),
    Color3.fromRGB(26, 20, 44),
    Enum.Material.SmoothPlastic
)

local leaderboardSpawn = makePart(
    leaderboardFolder,
    "Spawn",
    Vector3.new(8, 1, 8),
    CFrame.new(Config.Areas.Leaderboard.Position + Vector3.new(0, 1, 12)),
    Config.Areas.Leaderboard.AccentColor,
    Enum.Material.Neon
)
leaderboardSpawn.Transparency = 1
leaderboardSpawn.CanCollide = false

local boardPart, boardLabel = makeLabelPart(
    leaderboardFolder,
    "TopCoinsBoard",
    Vector3.new(18, 12, 1),
    CFrame.new(Config.Areas.Leaderboard.Position + Vector3.new(0, 8, -8)),
    Enum.NormalId.Front,
    "Top Coins\nAguardando jogadores...",
    Config.UI.Theme.TextColor,
    Config.Areas.Leaderboard.AccentColor
)
boardLabel.Name = "TopCoinsLabel"

local podium = makePart(
    leaderboardFolder,
    "Podium",
    Vector3.new(18, 3, 8),
    CFrame.new(Config.Areas.Leaderboard.Position + Vector3.new(0, 1.5, 10)),
    Config.Areas.Leaderboard.AccentColor,
    Enum.Material.Neon
)
podium.CanCollide = true

local ambient = Instance.new("Sound")
ambient.Name = "AmbientLoop"
ambient.SoundId = Config.Audio.RoundStartSoundId
ambient.Volume = 0.15
ambient.Looped = true
ambient.Parent = hubFloor
