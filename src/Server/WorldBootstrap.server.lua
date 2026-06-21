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
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration = 0
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
    ArenaState.RegisterLobbySpawn(spawn)

    local stage = WorldBuilder.MakePart(
        lobby,
        "BriefingStage",
        Vector3.new(88, 2, 28),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 3, -22)),
        Color3.fromRGB(32, 40, 56),
        Enum.Material.Metal
    )
    stage:SetAttribute("SafeZone", true)
    local upperStage = WorldBuilder.MakePart(
        lobby,
        "UpperBriefingStage",
        Vector3.new(56, 2, 18),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 5, -34)),
        Color3.fromRGB(45, 57, 78),
        Enum.Material.SmoothPlastic
    )
    upperStage:SetAttribute("SafeZone", true)

    local archLeft = WorldBuilder.MakePart(lobby, "ArenaArchLeft", Vector3.new(8, 30, 8), CFrame.new(WorldData.Lobby.Position + Vector3.new(-42, 16, -52)), Color3.fromRGB(43, 55, 72), Enum.Material.Metal)
    local archRight = WorldBuilder.MakePart(lobby, "ArenaArchRight", Vector3.new(8, 30, 8), CFrame.new(WorldData.Lobby.Position + Vector3.new(42, 16, -52)), Color3.fromRGB(43, 55, 72), Enum.Material.Metal)
    local archTop = WorldBuilder.MakePart(lobby, "ArenaArchTop", Vector3.new(92, 6, 8), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 30, -52)), Color3.fromRGB(43, 55, 72), Enum.Material.Metal)
    local archAccent = WorldBuilder.MakePart(lobby, "ArenaArchAccent", Vector3.new(78, 1.4, 1.2), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 27, -47.5)), Config.UI.Theme.AccentColor, Enum.Material.Neon, {
        CanCollide = false,
        Transparency = 0.22,
    })
    WorldBuilder.AddPointLight(archAccent, Config.UI.Theme.AccentColor, 0.42, 24)

    local objectiveSign = WorldBuilder.MakePart(
        lobby,
        "ObjectiveSign",
        Vector3.new(68, 14, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 16, -47.5)),
        Color3.fromRGB(18, 24, 34),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddSurfaceText(objectiveSign, Enum.NormalId.Front, "CS Fan Zone Arena\nProteja seu nucleo, equipe sua dupla e domine o centro", VisualKit.Global.TextLight, 26)

    local queueSign = WorldBuilder.MakePart(
        lobby,
        "QueueStatusSign",
        Vector3.new(30, 10, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 12, 44)),
        Color3.fromRGB(24, 30, 43),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddSurfaceText(queueSign, Enum.NormalId.Front, "Fila\nAguardando jogadores", Config.UI.Theme.WarningColor, 26)

    local walkway = WorldBuilder.MakePart(
        lobby,
        "LobbyWalkway",
        Config.World.Lobby.WalkwaySize,
        CFrame.new(WorldData.Lobby.WalkwayPosition),
        Color3.fromRGB(57, 72, 97),
        Enum.Material.Metal
    )
    local viewDeck = WorldBuilder.MakePart(
        lobby,
        "LobbyViewDeck",
        Config.World.Lobby.ViewDeckSize,
        CFrame.new(WorldData.Lobby.ViewDeckPosition),
        Color3.fromRGB(65, 80, 108),
        Enum.Material.Metal
    )
    walkway:SetAttribute("SafeZone", true)
    viewDeck:SetAttribute("SafeZone", true)

    WorldBuilder.MakePart(lobby, "WalkwayRailLeft", Vector3.new(2, 4, Config.World.Lobby.WalkwaySize.Z), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(-17, 3, 0)), Color3.fromRGB(36, 46, 61), Enum.Material.Metal, { Transparency = 0.1 })
    WorldBuilder.MakePart(lobby, "WalkwayRailRight", Vector3.new(2, 4, Config.World.Lobby.WalkwaySize.Z), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(17, 3, 0)), Color3.fromRGB(36, 46, 61), Enum.Material.Metal, { Transparency = 0.1 })
    WorldBuilder.MakePart(lobby, "WalkwayGuide", Vector3.new(8, 0.4, Config.World.Lobby.WalkwaySize.Z - 12), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(0, 1.3, 0)), Config.UI.Theme.AccentColor, Enum.Material.Neon, {
        CanCollide = false,
        Transparency = 0.62,
        CastShadow = false,
    })

    local overlookFrameLeft = WorldBuilder.MakePart(lobby, "OverlookFrameLeft", Vector3.new(14, 18, 8), CFrame.new(WorldData.Lobby.ViewDeckPosition + Vector3.new(-30, 10, -4)), Color3.fromRGB(31, 40, 54), Enum.Material.Metal)
    local overlookFrameRight = WorldBuilder.MakePart(lobby, "OverlookFrameRight", Vector3.new(14, 18, 8), CFrame.new(WorldData.Lobby.ViewDeckPosition + Vector3.new(30, 10, -4)), Color3.fromRGB(31, 40, 54), Enum.Material.Metal)
    local overlookFrameTop = WorldBuilder.MakePart(lobby, "OverlookFrameTop", Vector3.new(74, 4, 8), CFrame.new(WorldData.Lobby.ViewDeckPosition + Vector3.new(0, 19, -4)), Color3.fromRGB(31, 40, 54), Enum.Material.Metal)
    overlookFrameLeft:SetAttribute("SafeZone", true)
    overlookFrameRight:SetAttribute("SafeZone", true)
    overlookFrameTop:SetAttribute("SafeZone", true)

    for index, teamConfig in ipairs(Config.Teams) do
        local kit = VisualKit.Biomes[teamConfig.BiomeId]
        local angle = math.rad((index - 1) * 60)
        local totemPosition = WorldData.Lobby.Position + Vector3.new(math.cos(angle) * 52, 2, math.sin(angle) * 28)
        local pedestal = WorldBuilder.MakePart(lobby, "BiomeTotem_" .. teamConfig.Id, Vector3.new(10, 8, 10), CFrame.new(totemPosition + Vector3.new(0, 4, 0)), Color3.fromRGB(23, 29, 40), Enum.Material.SmoothPlastic)
        local accent = WorldBuilder.MakePart(lobby, "BiomeTotemAccent_" .. teamConfig.Id, Vector3.new(7, 0.8, 7), CFrame.new(totemPosition + Vector3.new(0, 8.4, 0)), kit.Accent, Enum.Material.SmoothPlastic)
        local face = WorldBuilder.MakePart(lobby, "BiomeTotemFace_" .. teamConfig.Id, Vector3.new(8, 3.2, 0.6), CFrame.new(totemPosition + Vector3.new(0, 4.8, -5.2)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
            CanCollide = false,
        })
        WorldBuilder.AddSurfaceText(face, Enum.NormalId.Front, teamConfig.BiomeDisplayName, kit.Accent, 24)
        pedestal:SetAttribute("SafeZone", true)
        accent:SetAttribute("SafeZone", true)
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
    WorldBuilder.BuildRouteMarkers(folder, teamConfig.BasePosition + Vector3.new(0, 1.2, -32), Vector3.new(0, 1.2, 0), kit.Accent)

    local spawn = makeSpawn(folder, "Spawn", CFrame.new(teamConfig.BasePosition + layout.SpawnOffset), teamConfig.Color, false, teamConfig.Color)
    ArenaState.RegisterTeamSpawn(teamConfig.Id, spawn)
    WorldBuilder.MakePart(folder, "SpawnTrim", Vector3.new(16, 0.5, 16), CFrame.new(teamConfig.BasePosition + layout.SpawnOffset + Vector3.new(0, -0.4, 0)), teamConfig.Color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.SmoothPlastic, {
        CanCollide = false,
        Transparency = 0.16,
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
        { Transparency = 0.62 }
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
        Transparency = 0.8,
        CastShadow = false,
    })
    WorldBuilder.AddPointLight(ring, VisualKit.Global.Emerald, 0.32, 28)

    local tower = WorldBuilder.MakePart(centerFolder, "EmeraldTower", Vector3.new(12, 34, 12), CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 17, 0)), VisualKit.Global.Emerald, Enum.Material.Glass, {
        Transparency = 0.32,
    })
    WorldBuilder.AddParticles(tower, VisualKit.Global.Emerald, 3.2, 1.6)
    local centerSign = WorldBuilder.MakePart(centerFolder, "CenterSign", Vector3.new(22, 4, 1), CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 8, -26)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddSurfaceText(centerSign, Enum.NormalId.Front, "Centro de Esmeraldas", VisualKit.Global.TextLight, 24)

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
            Vector3.new(7, 11, 7),
            CFrame.new(island.Position + Vector3.new(0, 7, -8)),
            Color3.fromRGB(38, 48, 63),
            Enum.Material.Metal,
            { Transparency = 0.04 }
        )
        local cap = WorldBuilder.MakePart(islandFolder, "MidRouteCap", Vector3.new(5, 1, 5), CFrame.new(island.Position + Vector3.new(0, 13, -8)), VisualKit.Global.Emerald, Enum.Material.Neon, {
            CanCollide = false,
            Transparency = 0.35,
        })
        WorldBuilder.AddPointLight(cap, VisualKit.Global.Emerald, 0.28, 10)

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
    local spectatorSpawn = makeSpawn(
        root,
        "SpectatorSpawn",
        CFrame.new(WorldData.SpectatorDeck.Position + Vector3.new(0, 2, 0)),
        Color3.fromRGB(90, 104, 130),
        true
    )
    spectatorSpawn.Transparency = 1
    spectatorSpawn.CanCollide = false
    local deckSign = WorldBuilder.MakePart(root, "SpectatorSign", Vector3.new(16, 3.4, 1), CFrame.new(WorldData.SpectatorDeck.Position + Vector3.new(0, 5, -20)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddSurfaceText(deckSign, Enum.NormalId.Front, "Espectador", VisualKit.Global.TextLight, 24)
    ArenaState.RegisterSpectatorSpawn(spectatorSpawn)
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
