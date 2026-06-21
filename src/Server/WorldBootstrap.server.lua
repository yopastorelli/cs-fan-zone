local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldData = require(Shared:WaitForChild("WorldData"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

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
    gui.PixelsPerStud = 32
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

local function addBillboard(part, name, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = name
    billboard.Size = UDim2.fromOffset(220, 66)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Config.UI.Theme.PanelColor
    label.BackgroundTransparency = 0.12
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    return billboard
end

local function addPrompt(parent, name, actionText, objectText, holdDuration)
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

local function buildIsland(parent, centerPosition, size, color, material)
    local base = makePart(parent, "IslandBase", size, CFrame.new(centerPosition + Vector3.new(0, -3, 0)), color, material)
    local lip = makePart(parent, "IslandLip", Vector3.new(size.X + 8, 2, size.Z + 8), CFrame.new(centerPosition + Vector3.new(0, -6, 0)), color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Rock)
    lip.Transparency = 0.05
    for _, offset in ipairs({
        Vector3.new(-size.X * 0.2, -10, -size.Z * 0.2),
        Vector3.new(size.X * 0.2, -10, -size.Z * 0.2),
        Vector3.new(0, -10, size.Z * 0.25),
    }) do
        local support = makePart(parent, "IslandSupport", Vector3.new(8, 12, 8), CFrame.new(centerPosition + offset), color:Lerp(Color3.new(0, 0, 0), 0.35), Enum.Material.Rock)
        support.Shape = Enum.PartType.Cylinder
        support.Orientation = Vector3.new(0, 0, 90)
    end
    return base, lip
end

local function addRail(parent, center, size)
    local rail = makePart(parent, "Rail", size, CFrame.new(center), Color3.fromRGB(168, 182, 201), Enum.Material.Metal)
    rail.Transparency = 0.15
    return rail
end

local function addGuideSign(parent, titleText, bodyText, position, color)
    local sign = makePart(parent, "GuideSign", Vector3.new(18, 10, 1), CFrame.new(position), color, Enum.Material.Neon)
    sign.CanCollide = false
    local gui = addSurfaceText(sign, Enum.NormalId.Front, titleText .. "\n" .. bodyText, Config.UI.Theme.TextColor)
    gui.PixelsPerStud = 24
    return sign
end

local function addGeneratorLabel(generator, labelText)
    addBillboard(generator, "GeneratorBillboard", labelText, Config.UI.Theme.TextColor)
end

local function buildLobby(root)
    local folder = makeFolder(root, "Lobby")
    local lobbyConfig = Config.World.Lobby

    local floor = makePart(
        folder,
        "LobbyFloor",
        lobbyConfig.PlatformSize,
        CFrame.new(WorldData.Lobby.Position),
        Color3.fromRGB(49, 60, 78),
        Enum.Material.Slate
    )

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LobbySpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = Config.UI.Theme.AccentColor
    spawn.CFrame = CFrame.new(Config.World.Lobby.SpawnPosition)
    spawn.Parent = folder

    local stage = makePart(
        folder,
        "BriefingStage",
        Vector3.new(54, 2, 22),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 3, -24)),
        Color3.fromRGB(29, 36, 50),
        Enum.Material.SmoothPlastic
    )
    stage.Transparency = 0.08

    local titleSign = makePart(
        folder,
        "ObjectiveSign",
        Vector3.new(44, 14, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 14, -48)),
        Config.UI.Theme.AccentColor,
        Enum.Material.Neon
    )
    titleSign.CanCollide = false
    addSurfaceText(titleSign, Enum.NormalId.Front, "Objetivo\nProteja seu nucleo e destrua os inimigos", Config.UI.Theme.TextColor)

    addGuideSign(folder, "1", "Colete ferro, ouro e esmeralda", WorldData.Lobby.Position + Vector3.new(-32, 11, -4), Color3.fromRGB(72, 104, 166))
    addGuideSign(folder, "2", "Compre blocos, espada e upgrades", WorldData.Lobby.Position + Vector3.new(0, 11, -4), Color3.fromRGB(83, 124, 95))
    addGuideSign(folder, "3", "Derrube o nucleo para eliminar a dupla", WorldData.Lobby.Position + Vector3.new(32, 11, -4), Color3.fromRGB(164, 91, 91))

    local queueSign = makePart(
        folder,
        "QueueStatusSign",
        Vector3.new(30, 10, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 10, 34)),
        Config.UI.Theme.WarningColor,
        Enum.Material.Neon
    )
    queueSign.CanCollide = false
    addSurfaceText(queueSign, Enum.NormalId.Front, "Fila\nAguardando jogadores", Color3.fromRGB(20, 24, 30))

    local walkway = makePart(
        folder,
        "LobbyWalkway",
        lobbyConfig.WalkwaySize,
        CFrame.new(WorldData.Lobby.WalkwayPosition),
        Color3.fromRGB(64, 78, 98),
        Enum.Material.Metal
    )
    local viewDeck = makePart(
        folder,
        "LobbyViewDeck",
        lobbyConfig.ViewDeckSize,
        CFrame.new(WorldData.Lobby.ViewDeckPosition),
        Color3.fromRGB(80, 98, 120),
        Enum.Material.Metal
    )
    addGuideSign(folder, "Arena", "Observe o centro e as seis bases antes da partida", WorldData.Lobby.ViewDeckPosition + Vector3.new(0, 10, -18), Config.UI.Theme.SuccessColor)

    addRail(folder, WorldData.Lobby.WalkwayPosition + Vector3.new(-16, 3, 0), Vector3.new(2, 6, lobbyConfig.WalkwaySize.Z))
    addRail(folder, WorldData.Lobby.WalkwayPosition + Vector3.new(16, 3, 0), Vector3.new(2, 6, lobbyConfig.WalkwaySize.Z))

    floor:SetAttribute("SafeZone", true)
    walkway:SetAttribute("SafeZone", true)
    viewDeck:SetAttribute("SafeZone", true)
end

local function buildBase(root, teamConfig)
    local biome = Config.Biomes[teamConfig.BiomeId]
    local folder = makeFolder(root, teamConfig.Id)
    local layout = WorldData.BaseLayout

    buildIsland(folder, teamConfig.BasePosition, layout.IslandSize, biome.FloorColor, biome.DetailMaterial)

    local sign = makePart(
        folder,
        "BaseSign",
        Vector3.new(30, 10, 1),
        CFrame.new(teamConfig.BasePosition + Vector3.new(0, 12, -30)),
        teamConfig.Color,
        Enum.Material.Neon
    )
    sign.CanCollide = false
    addSurfaceText(sign, Enum.NormalId.Front, teamConfig.BiomeDisplayName, Config.UI.Theme.TextColor)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Spawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.Anchored = true
    spawn.Neutral = false
    spawn.TeamColor = BrickColor.new(teamConfig.Color)
    spawn.Color = teamConfig.Color
    spawn.Material = Enum.Material.Neon
    spawn.CFrame = CFrame.new(teamConfig.BasePosition + layout.SpawnOffset)
    spawn.Parent = folder

    local core = makePart(
        folder,
        "Core",
        Vector3.new(8, 8, 8),
        CFrame.new(teamConfig.BasePosition + layout.CoreOffset),
        teamConfig.Color,
        Enum.Material.ForceField
    )
    core.Shape = Enum.PartType.Ball
    core:SetAttribute("CoreTeamId", teamConfig.Id)
    core:SetAttribute("CoreHealth", Config.Match.MaxCoreHealth)
    addBillboard(core, "CoreStatus", "Nucleo 6/6", Config.UI.Theme.TextColor)
    ArenaState.RegisterCore(teamConfig.Id, core)

    local itemShop = makePart(
        folder,
        "ItemShop",
        Vector3.new(6, 8, 6),
        CFrame.new(teamConfig.BasePosition + layout.ShopOffset),
        Color3.fromRGB(61, 82, 118),
        Enum.Material.SmoothPlastic
    )
    itemShop:SetAttribute("ShopKind", "Items")
    itemShop:SetAttribute("TeamId", teamConfig.Id)
    addBillboard(itemShop, "ItemBillboard", "Loja", Config.UI.Theme.TextColor)
    addPrompt(itemShop, "ItemShopPrompt", "Abrir", "Loja")
    ArenaState.RegisterShop(teamConfig.Id, "Items", itemShop)

    local upgradeShop = makePart(
        folder,
        "UpgradeShop",
        Vector3.new(6, 8, 6),
        CFrame.new(teamConfig.BasePosition + layout.UpgradeOffset),
        Color3.fromRGB(88, 74, 128),
        Enum.Material.SmoothPlastic
    )
    upgradeShop:SetAttribute("ShopKind", "Upgrades")
    upgradeShop:SetAttribute("TeamId", teamConfig.Id)
    addBillboard(upgradeShop, "UpgradeBillboard", "Upgrades", Config.UI.Theme.TextColor)
    addPrompt(upgradeShop, "UpgradeShopPrompt", "Abrir", "Upgrades")
    ArenaState.RegisterShop(teamConfig.Id, "Upgrades", upgradeShop)

    local generatorsFolder = makeFolder(folder, "Generators")

    local ironGenerator = makePart(
        generatorsFolder,
        "BaseIron",
        Vector3.new(4, 1, 4),
        CFrame.new(teamConfig.BasePosition + layout.IronGeneratorOffset),
        Color3.fromRGB(210, 217, 224),
        Enum.Material.Metal
    )
    ironGenerator:SetAttribute("GeneratorType", "BaseIron")
    ironGenerator:SetAttribute("TeamId", teamConfig.Id)
    addGeneratorLabel(ironGenerator, "Ferro")

    local goldGenerator = makePart(
        generatorsFolder,
        "BaseGold",
        Vector3.new(4, 1, 4),
        CFrame.new(teamConfig.BasePosition + layout.GoldGeneratorOffset),
        Color3.fromRGB(245, 205, 48),
        Enum.Material.Neon
    )
    goldGenerator:SetAttribute("GeneratorType", "BaseGold")
    goldGenerator:SetAttribute("TeamId", teamConfig.Id)
    addGeneratorLabel(goldGenerator, "Ouro")

    local defenseRing = makePart(
        folder,
        "DefensePad",
        Vector3.new(24, 1, 20),
        CFrame.new(teamConfig.BasePosition + Vector3.new(0, 1, -2)),
        teamConfig.Color:Lerp(Color3.new(0, 0, 0), 0.25),
        Enum.Material.SmoothPlastic
    )
    defenseRing.Transparency = 0.45
    defenseRing.CanCollide = true

    local biomeMarker = makePart(
        folder,
        "BiomeMarker",
        Vector3.new(12, 18, 12),
        CFrame.new(teamConfig.BasePosition + Vector3.new(0, 9, 28)),
        biome.AccentColor,
        Enum.Material.Glass
    )
    biomeMarker.Transparency = 0.35
    biomeMarker.CanCollide = false
end

local function buildCenter(root)
    local centerFolder = makeFolder(root, "Center")
    buildIsland(centerFolder, WorldData.CenterIsland.Position, WorldData.CenterIsland.Size, Color3.fromRGB(58, 65, 78), Enum.Material.Slate)

    local centerSign = makePart(
        centerFolder,
        "CenterSign",
        Vector3.new(30, 10, 1),
        CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 12, -24)),
        Config.UI.Theme.AccentColor,
        Enum.Material.Neon
    )
    centerSign.CanCollide = false
    addSurfaceText(centerSign, Enum.NormalId.Front, "Centro\nEsmeraldas premium", Config.UI.Theme.TextColor)

    local generatorsFolder = makeFolder(centerFolder, "Generators")
    for index, position in ipairs(WorldData.CenterEmeraldGenerators) do
        local generator = makePart(
            generatorsFolder,
            string.format("MidEmerald%d", index),
            Vector3.new(4, 1, 4),
            CFrame.new(WorldData.CenterIsland.Position + position),
            Color3.fromRGB(23, 226, 154),
            Enum.Material.Neon
        )
        generator:SetAttribute("GeneratorType", "MidEmerald")
        addGeneratorLabel(generator, "Esmeralda")
    end
end

local function buildMidIslands(root)
    local folder = makeFolder(root, "MidIslands")
    for _, island in ipairs(WorldData.MidIslands) do
        buildIsland(folder, island.Position, island.Size, Color3.fromRGB(74, 86, 98), Enum.Material.Rock)
        local marker = makePart(
            folder,
            island.Id .. "Marker",
            Vector3.new(10, 5, 1),
            CFrame.new(island.Position + Vector3.new(0, 7, -8)),
            Config.UI.Theme.WarningColor,
            Enum.Material.Neon
        )
        marker.CanCollide = false
        addSurfaceText(marker, Enum.NormalId.Front, "Esmeralda", Config.UI.Theme.TextColor)

        local generator = makePart(
            folder,
            island.Id .. "Generator",
            Vector3.new(4, 1, 4),
            CFrame.new(island.Position + Vector3.new(0, 2.5, 0)),
            Color3.fromRGB(23, 226, 154),
            Enum.Material.Neon
        )
        generator:SetAttribute("GeneratorType", "MidEmerald")
        addGeneratorLabel(generator, "Esmeralda")
    end
end

local function buildSpectatorDeck(root)
    local deck = makePart(
        root,
        "SpectatorDeck",
        WorldData.SpectatorDeck.Size,
        CFrame.new(WorldData.SpectatorDeck.Position),
        Color3.fromRGB(35, 42, 56),
        Enum.Material.Metal
    )
    deck.Transparency = 0.1
    ArenaState.RegisterSpectatorSpawn(deck)
end

local function buildArenaBackdrop(root)
    local backdrop = makeFolder(root, "Backdrop")
    for index, angle in ipairs({ 0, 60, 120, 180, 240, 300 }) do
        local radians = math.rad(angle)
        local position = Vector3.new(math.cos(radians) * 260, -8, math.sin(radians) * 260)
        local wall = makePart(
            backdrop,
            "BackdropWall" .. tostring(index),
            Vector3.new(90, 40, 10),
            CFrame.new(position) * CFrame.Angles(0, radians, 0),
            Color3.fromRGB(28, 33, 44),
            Enum.Material.Slate
        )
        wall.Transparency = 0.15
    end
end

ArenaState.Initialize()

local worldRoot = ensureWorldRoot()
buildLobby(worldRoot)
buildCenter(worldRoot)
buildMidIslands(worldRoot)
for _, teamConfig in ipairs(Config.Teams) do
    buildBase(worldRoot, teamConfig)
end
buildSpectatorDeck(worldRoot)
buildArenaBackdrop(worldRoot)
