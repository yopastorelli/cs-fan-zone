local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldData = require(Shared:WaitForChild("WorldData"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

Remotes.GetAll()

local WORLD_NAME = "CSFanZone"

local CenterKit = {
    Primary = Color3.fromRGB(47, 58, 76),
    Secondary = Color3.fromRGB(74, 91, 118),
    Rim = Color3.fromRGB(25, 34, 48),
    Underside = Color3.fromRGB(18, 24, 36),
    Accent = VisualKit.Global.Emerald,
    Material = Enum.Material.Slate,
    DetailMaterial = Enum.Material.Metal,
    Landmark = "crystal",
    PropStyle = "crystals",
}

local LobbyKit = {
    Primary = Color3.fromRGB(45, 57, 78),
    Secondary = Color3.fromRGB(71, 92, 124),
    Rim = Color3.fromRGB(28, 35, 50),
    Underside = Color3.fromRGB(18, 24, 36),
    Accent = Config.UI.Theme.AccentColor,
    Material = Enum.Material.Slate,
    DetailMaterial = Enum.Material.Metal,
    Landmark = "crystal",
    PropStyle = "crystals",
}

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

local function makeSpawn(parent, name, cframe, color, neutral, teamColor)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = name
    spawn.Size = Vector3.new(11, 1, 11)
    spawn.Anchored = true
    spawn.Neutral = neutral
    spawn.Color = color
    spawn.Material = Enum.Material.Neon
    spawn.CFrame = cframe
    if teamColor then
        spawn.TeamColor = BrickColor.new(teamColor)
    end
    spawn.Parent = parent
    return spawn
end

local function buildLobby(root)
    local lobby = WorldBuilder.BuildIsland(root, "Lobby", WorldData.Lobby.Position, Config.World.Lobby.PlatformSize, LobbyKit, {
        Glow = true,
    })

    local spawn = makeSpawn(lobby, "LobbySpawn", CFrame.new(Config.World.Lobby.SpawnPosition), Config.UI.Theme.AccentColor, true)
    spawn:SetAttribute("SafeZone", true)

    local stage = WorldBuilder.MakePart(
        lobby,
        "BriefingStage",
        Vector3.new(72, 2, 24),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 3, -26)),
        VisualKit.Global.MetalDark,
        Enum.Material.Metal
    )
    stage:SetAttribute("SafeZone", true)

    local archLeft = WorldBuilder.MakePart(lobby, "ArenaArchLeft", Vector3.new(6, 28, 6), CFrame.new(WorldData.Lobby.Position + Vector3.new(-42, 15, -48)), Config.UI.Theme.AccentColor, Enum.Material.Neon)
    local archRight = WorldBuilder.MakePart(lobby, "ArenaArchRight", Vector3.new(6, 28, 6), CFrame.new(WorldData.Lobby.Position + Vector3.new(42, 15, -48)), Config.UI.Theme.AccentColor, Enum.Material.Neon)
    local archTop = WorldBuilder.MakePart(lobby, "ArenaArchTop", Vector3.new(90, 5, 6), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 29, -48)), Config.UI.Theme.AccentColor, Enum.Material.Neon)
    WorldBuilder.AddPointLight(archTop, Config.UI.Theme.AccentColor, 1.3, 36)

    local objectiveSign = WorldBuilder.MakePart(
        lobby,
        "ObjectiveSign",
        Vector3.new(62, 14, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 15, -51)),
        Color3.fromRGB(240, 248, 255),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddSurfaceText(objectiveSign, Enum.NormalId.Front, "Proteja seu nucleo\nColete recursos, compre itens e quebre os nucleos inimigos", VisualKit.Global.TextDark, 26)

    local queueSign = WorldBuilder.MakePart(
        lobby,
        "QueueStatusSign",
        Vector3.new(30, 10, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 12, 38)),
        Config.UI.Theme.WarningColor,
        Enum.Material.Neon,
        { CanCollide = false }
    )
    WorldBuilder.AddSurfaceText(queueSign, Enum.NormalId.Front, "Fila\nAguardando jogadores", VisualKit.Global.TextDark, 26)

    local walkway = WorldBuilder.MakePart(
        lobby,
        "LobbyWalkway",
        Config.World.Lobby.WalkwaySize,
        CFrame.new(WorldData.Lobby.WalkwayPosition),
        VisualKit.Global.MetalMid,
        Enum.Material.Metal
    )
    local viewDeck = WorldBuilder.MakePart(
        lobby,
        "LobbyViewDeck",
        Config.World.Lobby.ViewDeckSize,
        CFrame.new(WorldData.Lobby.ViewDeckPosition),
        Color3.fromRGB(88, 112, 146),
        Enum.Material.Metal
    )
    walkway:SetAttribute("SafeZone", true)
    viewDeck:SetAttribute("SafeZone", true)

    WorldBuilder.MakePart(lobby, "WalkwayRailLeft", Vector3.new(2, 6, Config.World.Lobby.WalkwaySize.Z), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(-17, 4, 0)), Config.UI.Theme.AccentColor, Enum.Material.Neon, { Transparency = 0.22 })
    WorldBuilder.MakePart(lobby, "WalkwayRailRight", Vector3.new(2, 6, Config.World.Lobby.WalkwaySize.Z), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(17, 4, 0)), Config.UI.Theme.AccentColor, Enum.Material.Neon, { Transparency = 0.22 })

    for index, teamConfig in ipairs(Config.Teams) do
        local kit = VisualKit.Biomes[teamConfig.BiomeId]
        local angle = math.rad((index - 1) * 60)
        local totemPosition = WorldData.Lobby.Position + Vector3.new(math.cos(angle) * 55, 2, math.sin(angle) * 32)
        local totem = WorldBuilder.MakePart(lobby, "BiomeTotem_" .. teamConfig.Id, Vector3.new(8, 12, 8), CFrame.new(totemPosition + Vector3.new(0, 6, 0)), kit.Accent, Enum.Material.Neon, {
            Transparency = 0.08,
        })
        WorldBuilder.AddBillboard(totem, "TotemLabel", teamConfig.BiomeDisplayName, VisualKit.Global.TextLight, UDim2.fromOffset(150, 42), Vector3.new(0, 8, 0))
    end

    archLeft:SetAttribute("SafeZone", true)
    archRight:SetAttribute("SafeZone", true)
    archTop:SetAttribute("SafeZone", true)
end

local function buildBase(root, teamConfig)
    local kit = VisualKit.Biomes[teamConfig.BiomeId]
    local layout = WorldData.BaseLayout
    local folder = WorldBuilder.BuildIsland(root, teamConfig.Id, teamConfig.BasePosition, layout.IslandSize, kit, {
        Glow = true,
    })

    WorldBuilder.BuildLandmark(folder, teamConfig.BasePosition, kit, teamConfig.BiomeDisplayName)
    WorldBuilder.BuildBiomeProps(folder, teamConfig.BasePosition, kit)
    WorldBuilder.BuildRouteMarkers(folder, teamConfig.BasePosition + Vector3.new(0, 2, -34), Vector3.new(0, 2, 0), kit.Accent)

    local spawn = makeSpawn(folder, "Spawn", CFrame.new(teamConfig.BasePosition + layout.SpawnOffset), teamConfig.Color, false, teamConfig.Color)
    WorldBuilder.MakePart(folder, "SpawnTrim", Vector3.new(16, 0.5, 16), CFrame.new(teamConfig.BasePosition + layout.SpawnOffset + Vector3.new(0, -0.4, 0)), teamConfig.Color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Neon, {
        CanCollide = false,
        Transparency = 0.32,
    })

    local core = WorldBuilder.BuildCore(folder, teamConfig.BasePosition + layout.CoreOffset, teamConfig.Color)
    core:SetAttribute("CoreTeamId", teamConfig.Id)
    core:SetAttribute("CoreHealth", Config.Match.MaxCoreHealth)
    ArenaState.RegisterCore(teamConfig.Id, core)

    local itemShop = WorldBuilder.BuildShopStand(
        folder,
        "ItemShop",
        teamConfig.BasePosition + layout.ShopOffset,
        Color3.fromRGB(47, 100, 156),
        "Loja"
    )
    itemShop:SetAttribute("ShopKind", "Items")
    itemShop:SetAttribute("TeamId", teamConfig.Id)
    WorldBuilder.AddPrompt(itemShop, "ItemShopPrompt", "Abrir", "Loja")
    ArenaState.RegisterShop(teamConfig.Id, "Items", itemShop)

    local upgradeShop = WorldBuilder.BuildShopStand(
        folder,
        "UpgradeShop",
        teamConfig.BasePosition + layout.UpgradeOffset,
        Color3.fromRGB(116, 79, 168),
        "Upgrades"
    )
    upgradeShop:SetAttribute("ShopKind", "Upgrades")
    upgradeShop:SetAttribute("TeamId", teamConfig.Id)
    WorldBuilder.AddPrompt(upgradeShop, "UpgradeShopPrompt", "Abrir", "Upgrades")
    ArenaState.RegisterShop(teamConfig.Id, "Upgrades", upgradeShop)

    local generatorsFolder = WorldBuilder.MakeFolder(folder, "Generators")

    local ironGenerator = WorldBuilder.BuildGenerator(
        generatorsFolder,
        "BaseIron",
        teamConfig.BasePosition + layout.IronGeneratorOffset,
        VisualKit.Global.Iron,
        "Ferro"
    )
    ironGenerator:SetAttribute("GeneratorType", "BaseIron")
    ironGenerator:SetAttribute("TeamId", teamConfig.Id)

    local goldGenerator = WorldBuilder.BuildGenerator(
        generatorsFolder,
        "BaseGold",
        teamConfig.BasePosition + layout.GoldGeneratorOffset,
        VisualKit.Global.Gold,
        "Ouro"
    )
    goldGenerator:SetAttribute("GeneratorType", "BaseGold")
    goldGenerator:SetAttribute("TeamId", teamConfig.Id)

    local defensePad = WorldBuilder.MakePart(
        folder,
        "DefensePad",
        Vector3.new(28, 0.6, 22),
        CFrame.new(teamConfig.BasePosition + Vector3.new(0, 1, -2)),
        teamConfig.Color:Lerp(Color3.new(0, 0, 0), 0.18),
        Enum.Material.SmoothPlastic,
        { Transparency = 0.42 }
    )
    defensePad:SetAttribute("GameplayDecor", true)

    spawn:SetAttribute("GameplaySpawn", true)
end

local function buildCenter(root)
    local centerFolder = WorldBuilder.BuildIsland(root, "Center", WorldData.CenterIsland.Position, WorldData.CenterIsland.Size, CenterKit, {
        Glow = true,
    })

    local ring = WorldBuilder.MakePart(centerFolder, "EmeraldRing", Vector3.new(62, 1.2, 62), CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 2.4, 0)), VisualKit.Global.Emerald, Enum.Material.Neon, {
        CanCollide = false,
        Transparency = 0.62,
        CastShadow = false,
    })
    WorldBuilder.AddPointLight(ring, VisualKit.Global.Emerald, 1.1, 48)

    local tower = WorldBuilder.MakePart(centerFolder, "EmeraldTower", Vector3.new(12, 34, 12), CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 17, 0)), VisualKit.Global.Emerald, Enum.Material.Glass, {
        Transparency = 0.2,
    })
    WorldBuilder.AddParticles(tower, VisualKit.Global.Emerald, 8, 1.8)
    WorldBuilder.AddBillboard(tower, "CenterBillboard", "Centro\nEsmeraldas", VisualKit.Global.TextLight, UDim2.fromOffset(240, 80), Vector3.new(0, 24, 0))

    local generatorsFolder = WorldBuilder.MakeFolder(centerFolder, "Generators")
    for index, position in ipairs(WorldData.CenterEmeraldGenerators) do
        local generator = WorldBuilder.BuildGenerator(
            generatorsFolder,
            string.format("MidEmerald%d", index),
            WorldData.CenterIsland.Position + position,
            VisualKit.Global.Emerald,
            "Esmeralda"
        )
        generator:SetAttribute("GeneratorType", "MidEmerald")
    end
end

local function buildMidIslands(root)
    local folder = WorldBuilder.MakeFolder(root, "MidIslands")
    for _, island in ipairs(WorldData.MidIslands) do
        local islandFolder = WorldBuilder.BuildIsland(folder, island.Id, island.Position, island.Size, CenterKit, {
            Glow = false,
        })
        local marker = WorldBuilder.MakePart(
            islandFolder,
            "MidRoutePylon",
            Vector3.new(8, 14, 8),
            CFrame.new(island.Position + Vector3.new(0, 7, -8)),
            Config.UI.Theme.WarningColor,
            Enum.Material.Neon,
            { Transparency = 0.08 }
        )
        WorldBuilder.AddBillboard(marker, "MidLabel", "Rota\nEsmeralda", VisualKit.Global.TextLight, UDim2.fromOffset(170, 58), Vector3.new(0, 10, 0))

        local generator = WorldBuilder.BuildGenerator(
            islandFolder,
            island.Id .. "Generator",
            island.Position + Vector3.new(0, 2.5, 0),
            VisualKit.Global.Emerald,
            "Esmeralda"
        )
        generator:SetAttribute("GeneratorType", "MidEmerald")
    end
end

local function buildSpectatorDeck(root)
    local deck = WorldBuilder.MakePart(
        root,
        "SpectatorDeck",
        WorldData.SpectatorDeck.Size,
        CFrame.new(WorldData.SpectatorDeck.Position),
        Color3.fromRGB(35, 42, 56),
        Enum.Material.Metal,
        { Transparency = 0.08 }
    )
    WorldBuilder.AddBillboard(deck, "SpectatorLabel", "Espectador", VisualKit.Global.TextLight, UDim2.fromOffset(170, 48), Vector3.new(0, 6, 0))
    ArenaState.RegisterSpectatorSpawn(deck)
end

local function buildArenaBackdrop(root)
    local backdrop = WorldBuilder.MakeFolder(root, "Backdrop")
    for index, angle in ipairs({ 0, 60, 120, 180, 240, 300 }) do
        local radians = math.rad(angle)
        local position = Vector3.new(math.cos(radians) * 268, -8, math.sin(radians) * 268)
        local wall = WorldBuilder.MakePart(
            backdrop,
            "BackdropWall" .. tostring(index),
            Vector3.new(92, 44, 10),
            CFrame.new(position) * CFrame.Angles(0, radians, 0),
            VisualKit.Global.VoidColor,
            Enum.Material.Slate,
            { Transparency = 0.12 }
        )
        WorldBuilder.AddPointLight(wall, Config.UI.Theme.AccentColor, 0.25, 36)
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
