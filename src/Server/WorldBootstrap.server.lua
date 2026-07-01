local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldData = require(Shared:WaitForChild("WorldData"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local WorldRuntime = require(script.Parent:WaitForChild("WorldRuntime"))

Remotes.GetAll()
WorldBuilder.SetQualityTier((Config.Visual and Config.Visual.VisualQualityDefault) or "Low")

local WORLD_NAME = "CSFanZone"

local CenterKit = {
    Primary = Color3.fromRGB(92, 106, 82),
    Secondary = Color3.fromRGB(108, 94, 72),
    Rim = Color3.fromRGB(62, 72, 56),
    Underside = Color3.fromRGB(48, 52, 42),
    Accent = VisualKit.Global.Emerald,
    Material = Enum.Material.Rock,
    DetailMaterial = Enum.Material.Ground,
    Landmark = "oak",
    PropStyle = "flowers",
}

local LobbyKit = {
    Primary = Color3.fromRGB(96, 90, 76),
    Secondary = Color3.fromRGB(120, 108, 84),
    Rim = Color3.fromRGB(70, 64, 50),
    Underside = Color3.fromRGB(52, 48, 38),
    Accent = Config.UI.Theme.AccentColor,
    Material = Enum.Material.Rock,
    DetailMaterial = Enum.Material.Ground,
    Landmark = "oak",
    PropStyle = "flowers",
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

local function getFacingFrame(position, lookAtPosition)
    local target = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
    return CFrame.lookAt(position, target)
end

local function transformOffset(frame, offset)
    return frame:PointToWorldSpace(offset)
end

local function buildLobby(root)
    local lobby = WorldBuilder.BuildIsland(root, "Lobby", WorldData.Lobby.Position, Config.World.Lobby.PlatformSize, LobbyKit, {
        Glow = true,
    })

    local lobbyLookTarget = WorldData.CenterIsland.Position + Vector3.new(0, 0, 44)
    local lobbySpawnFrame = getFacingFrame(Config.World.Lobby.SpawnPosition, lobbyLookTarget)
    local spawn = makeSpawn(lobby, "LobbySpawn", lobbySpawnFrame, Config.UI.Theme.AccentColor, true)
    spawn:SetAttribute("SafeZone", true)
    ArenaState.RegisterLobbySpawn(spawn)

    local spawnTerrace = WorldBuilder.MakePart(
        lobby,
        "SpawnTerrace",
        Vector3.new(84, 2, 26),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 3, 28)),
        Color3.fromRGB(92, 100, 112),
        Enum.Material.Rock
    )
    spawnTerrace:SetAttribute("SafeZone", true)
    local centralPath = WorldBuilder.MakePart(
        lobby,
        "CentralPath",
        Vector3.new(42, 2, 74),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 3, -10)),
        Color3.fromRGB(98, 87, 72),
        Enum.Material.Ground
    )
    centralPath:SetAttribute("SafeZone", true)
    local overlookPad = WorldBuilder.MakePart(
        lobby,
        "OverlookPad",
        Vector3.new(70, 2, 22),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 5, -42)),
        Color3.fromRGB(78, 86, 98),
        Enum.Material.Slate
    )
    overlookPad:SetAttribute("SafeZone", true)

    local archLeft = WorldBuilder.MakePart(lobby, "ArenaArchLeft", Vector3.new(10, 26, 10), CFrame.new(WorldData.Lobby.Position + Vector3.new(-38, 14, -54)), Color3.fromRGB(63, 70, 82), Enum.Material.Rock)
    local archRight = WorldBuilder.MakePart(lobby, "ArenaArchRight", Vector3.new(10, 26, 10), CFrame.new(WorldData.Lobby.Position + Vector3.new(38, 14, -54)), Color3.fromRGB(63, 70, 82), Enum.Material.Rock)
    local archTop = WorldBuilder.MakePart(lobby, "ArenaArchTop", Vector3.new(86, 6, 10), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 25, -54)), Color3.fromRGB(63, 70, 82), Enum.Material.Rock)
    local archAccent = WorldBuilder.MakePart(lobby, "ArenaArchAccent", Vector3.new(70, 1.1, 1.4), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 22, -48.5)), Config.UI.Theme.AccentColor, Enum.Material.Neon, {
        CanCollide = false,
        Transparency = 0.72,
    })
    WorldBuilder.AddPointLight(archAccent, Config.UI.Theme.AccentColor, 0.12, {
        Range = 20,
        Category = "PureDecor",
    })

    local objectiveSign = WorldBuilder.MakePart(
        lobby,
        "ObjectiveSign",
        Vector3.new(36, 8, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 13, -47.8)),
        Color3.fromRGB(18, 24, 34),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddDoubleSurfaceText(objectiveSign, "Proteja o totem\nBase -> Meio -> Centro", VisualKit.Global.TextLight, 20)

    local queueSign = WorldBuilder.MakePart(
        lobby,
        "QueueStatusSign",
        Vector3.new(24, 10, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(-34, 12, 16)),
        Color3.fromRGB(24, 30, 43),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddDoubleSurfaceText(queueSign, "Fila\nAguardando", Config.UI.Theme.WarningColor, 22)

    local tacticalBoard = WorldBuilder.MakePart(
        lobby,
        "TacticalBoard",
        Vector3.new(30, 12, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(36, 13, 16)),
        Color3.fromRGB(24, 30, 43),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddDoubleSurfaceText(tacticalBoard, "Mapa rapido\nBase -> Ilha do Meio -> Centro", VisualKit.Global.TextLight, 20)

    local mapBoard = WorldBuilder.MakePart(
        lobby,
        "MiniMapBoard",
        Vector3.new(34, 16, 1),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 11, 36)),
        Color3.fromRGB(24, 30, 43),
        Enum.Material.SmoothPlastic,
        { CanCollide = false }
    )
    WorldBuilder.AddDoubleSurfaceText(mapBoard, "Mini mapa da rodada", VisualKit.Global.TextLight, 18)
    local mapNodeBase = WorldBuilder.MakePart(lobby, "MiniMapBase", Vector3.new(6, 1.2, 6), CFrame.new(WorldData.Lobby.Position + Vector3.new(-10, 3.5, 32)), Color3.fromRGB(241, 199, 74), Enum.Material.SmoothPlastic)
    local mapNodeMiddle = WorldBuilder.MakePart(lobby, "MiniMapMiddle", Vector3.new(6, 1.2, 6), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 3.5, 32)), VisualKit.Global.Emerald, Enum.Material.SmoothPlastic)
    local mapNodeCenter = WorldBuilder.MakePart(lobby, "MiniMapCenter", Vector3.new(7, 1.2, 7), CFrame.new(WorldData.Lobby.Position + Vector3.new(12, 3.5, 32)), Config.UI.Theme.AccentColor, Enum.Material.SmoothPlastic)
    local mapPath1 = WorldBuilder.MakePart(lobby, "MiniMapPath1", Vector3.new(8, 0.6, 1.4), CFrame.new(WorldData.Lobby.Position + Vector3.new(-5, 3.7, 32)), Color3.fromRGB(166, 142, 84), Enum.Material.WoodPlanks, { CanCollide = false })
    local mapPath2 = WorldBuilder.MakePart(lobby, "MiniMapPath2", Vector3.new(8, 0.6, 1.4), CFrame.new(WorldData.Lobby.Position + Vector3.new(6, 3.7, 32)), Color3.fromRGB(86, 160, 118), Enum.Material.WoodPlanks, { CanCollide = false })
    local mapBaseSign = WorldBuilder.MakePart(lobby, "MiniMapBaseSign", Vector3.new(6, 2, 0.8), CFrame.new(WorldData.Lobby.Position + Vector3.new(-10, 6, 35.8)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, { CanCollide = false })
    local mapMiddleSign = WorldBuilder.MakePart(lobby, "MiniMapMiddleSign", Vector3.new(8, 2, 0.8), CFrame.new(WorldData.Lobby.Position + Vector3.new(0, 6, 35.8)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, { CanCollide = false })
    local mapCenterSign = WorldBuilder.MakePart(lobby, "MiniMapCenterSign", Vector3.new(6, 2, 0.8), CFrame.new(WorldData.Lobby.Position + Vector3.new(12, 6, 35.8)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, { CanCollide = false })
    WorldBuilder.AddDoubleSurfaceText(mapBaseSign, "Base", VisualKit.Global.TextLight, 18)
    WorldBuilder.AddDoubleSurfaceText(mapMiddleSign, "Ilha do Meio", VisualKit.Global.TextLight, 16)
    WorldBuilder.AddDoubleSurfaceText(mapCenterSign, "Centro", VisualKit.Global.TextLight, 18)

    local previewPlatform = WorldBuilder.MakePart(
        lobby,
        "PreviewPlatform",
        Vector3.new(54, 2, 40),
        CFrame.new(WorldData.Lobby.Position + Vector3.new(64, 4, -16)),
        Color3.fromRGB(95, 88, 72),
        Enum.Material.Ground
    )
    previewPlatform:SetAttribute("SafeZone", true)
    local previewSign = WorldBuilder.MakePart(lobby, "PreviewSign", Vector3.new(18, 4, 1), CFrame.new(WorldData.Lobby.Position + Vector3.new(64, 11, 2)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, { CanCollide = false })
    WorldBuilder.AddDoubleSurfaceText(previewSign, "Exemplo da Base", VisualKit.Global.TextLight, 20)
    local previewKit = VisualKit.Biomes.planicie
    local previewCore = WorldBuilder.BuildCore(lobby, CFrame.new(WorldData.Lobby.Position + Vector3.new(64, 5, -22)), previewKit.Accent, "planicie", "Seu Totem")
    previewCore:SetAttribute("SafeZone", true)
    local previewIron = WorldBuilder.BuildGenerator(lobby, "PreviewIron", CFrame.new(WorldData.Lobby.Position + Vector3.new(56, 4, -8)), VisualKit.Global.Iron, "Ferro")
    local previewGold = WorldBuilder.BuildGenerator(lobby, "PreviewGold", CFrame.new(WorldData.Lobby.Position + Vector3.new(72, 4, -8)), VisualKit.Global.Gold, "Ouro")
    local previewShop = WorldBuilder.BuildShopStand(lobby, "PreviewShop", CFrame.new(WorldData.Lobby.Position + Vector3.new(48, 6, -22)), Color3.fromRGB(47, 100, 156), "Loja")
    local previewUpgrade = WorldBuilder.BuildShopStand(lobby, "PreviewUpgrade", CFrame.new(WorldData.Lobby.Position + Vector3.new(80, 6, -22)), Color3.fromRGB(116, 79, 168), "Upgrades")
    local previewMiddle = WorldBuilder.BuildRouteMouth(lobby, "PreviewMiddleRoute", CFrame.new(WorldData.Lobby.Position + Vector3.new(54, 4.2, -31)), Color3.fromRGB(245, 202, 80), "Ilha do Meio")
    local previewCenter = WorldBuilder.BuildRouteMouth(lobby, "PreviewCenterRoute", CFrame.new(WorldData.Lobby.Position + Vector3.new(74, 4.2, -31)), VisualKit.Global.Emerald, "Centro")
    for _, inst in ipairs({ previewIron, previewGold, previewShop, previewUpgrade }) do
        inst:SetAttribute("SafeZone", true)
    end
    for _, folder in ipairs({ previewMiddle, previewCenter }) do
        for _, descendant in ipairs(folder:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant:SetAttribute("SafeZone", true)
            end
        end
    end

    local walkway = WorldBuilder.MakePart(
        lobby,
        "LobbyWalkway",
        Config.World.Lobby.WalkwaySize,
        CFrame.new(WorldData.Lobby.WalkwayPosition),
        Color3.fromRGB(88, 80, 68),
        Enum.Material.Ground
    )
    local viewDeck = WorldBuilder.MakePart(
        lobby,
        "LobbyViewDeck",
        Config.World.Lobby.ViewDeckSize,
        CFrame.new(WorldData.Lobby.ViewDeckPosition),
        Color3.fromRGB(78, 86, 98),
        Enum.Material.Slate
    )
    walkway:SetAttribute("SafeZone", true)
    viewDeck:SetAttribute("SafeZone", true)

    WorldBuilder.MakePart(lobby, "WalkwayRailLeft", Vector3.new(2, 4, Config.World.Lobby.WalkwaySize.Z), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(-17, 3, 0)), Color3.fromRGB(70, 53, 40), Enum.Material.WoodPlanks, { Transparency = 0.04 })
    WorldBuilder.MakePart(lobby, "WalkwayRailRight", Vector3.new(2, 4, Config.World.Lobby.WalkwaySize.Z), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(17, 3, 0)), Color3.fromRGB(70, 53, 40), Enum.Material.WoodPlanks, { Transparency = 0.04 })
    WorldBuilder.MakePart(lobby, "WalkwayGuide", Vector3.new(8, 0.4, Config.World.Lobby.WalkwaySize.Z - 12), CFrame.new(WorldData.Lobby.WalkwayPosition + Vector3.new(0, 1.3, 0)), Config.UI.Theme.AccentColor, Enum.Material.SmoothPlastic, {
        CanCollide = false,
        Transparency = 0.94,
        CastShadow = false,
    })

    local overlookFrameLeft = WorldBuilder.MakePart(lobby, "OverlookFrameLeft", Vector3.new(12, 16, 8), CFrame.new(WorldData.Lobby.ViewDeckPosition + Vector3.new(-28, 9, -4)), Color3.fromRGB(64, 72, 82), Enum.Material.Rock)
    local overlookFrameRight = WorldBuilder.MakePart(lobby, "OverlookFrameRight", Vector3.new(12, 16, 8), CFrame.new(WorldData.Lobby.ViewDeckPosition + Vector3.new(28, 9, -4)), Color3.fromRGB(64, 72, 82), Enum.Material.Rock)
    local overlookFrameTop = WorldBuilder.MakePart(lobby, "OverlookFrameTop", Vector3.new(68, 4, 8), CFrame.new(WorldData.Lobby.ViewDeckPosition + Vector3.new(0, 17, -4)), Color3.fromRGB(64, 72, 82), Enum.Material.Rock)
    overlookFrameLeft:SetAttribute("SafeZone", true)
    overlookFrameRight:SetAttribute("SafeZone", true)
    overlookFrameTop:SetAttribute("SafeZone", true)

    for index, teamConfig in ipairs(Config.Teams) do
        local kit = VisualKit.Biomes[teamConfig.BiomeId]
        local side = index <= 3 and -1 or 1
        local rowIndex = ((index - 1) % 3)
        local totemPosition = WorldData.Lobby.Position + Vector3.new(side * 48, 3, 26 - (rowIndex * 28))
        local totemFaceFrame = getFacingFrame(totemPosition, Config.World.Lobby.SpawnPosition + Vector3.new(0, 0, -48))
        local pedestal = WorldBuilder.MakePart(lobby, "BiomeTotem_" .. teamConfig.Id, Vector3.new(10, 8, 10), CFrame.new(totemPosition + Vector3.new(0, 4, 0)), Color3.fromRGB(23, 29, 40), Enum.Material.Slate)
        local accent = WorldBuilder.MakePart(lobby, "BiomeTotemAccent_" .. teamConfig.Id, Vector3.new(8, 1.2, 8), CFrame.new(totemPosition + Vector3.new(0, 8.6, 0)), kit.Accent, Enum.Material.SmoothPlastic)
        local face = WorldBuilder.MakePart(lobby, "BiomeTotemFace_" .. teamConfig.Id, Vector3.new(8, 3.2, 0.8), totemFaceFrame * CFrame.new(0, 1.2, -5.1), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
            CanCollide = false,
        })
        WorldBuilder.AddDoubleSurfaceText(face, teamConfig.BiomeDisplayName, kit.Accent, 18)
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
    local baseFrame = getFacingFrame(teamConfig.BasePosition, WorldData.CenterIsland.Position)
    local folder = WorldBuilder.BuildIsland(root, teamConfig.Id, teamConfig.BasePosition, layout.IslandSize, kit, {
        Glow = true,
    })

    local landmarkFrame = baseFrame * CFrame.new(0, 16, -34)
    WorldBuilder.BuildLandmark(folder, landmarkFrame, kit, teamConfig.BiomeDisplayName)
    WorldBuilder.BuildBiomeProps(folder, teamConfig.BasePosition, kit)
    WorldBuilder.BuildRouteMarkers(folder, transformOffset(baseFrame, Vector3.new(0, 1.2, -34)), transformOffset(baseFrame, Vector3.new(0, 1.2, -8)), kit.Accent)
    WorldBuilder.BuildRouteMouth(folder, "MidRouteMouth", baseFrame * CFrame.new(-16, 1.2, -34), kit.Accent, "Meio")
    WorldBuilder.BuildRouteMouth(folder, "CenterRouteMouth", baseFrame * CFrame.new(16, 1.2, -34), kit.Accent:Lerp(VisualKit.Global.Emerald, 0.18), "Centro")
    WorldBuilder.MakePart(folder, "MiddleArrowStem", Vector3.new(4, 0.6, 9), baseFrame * CFrame.new(-16, 1.5, -23), Color3.fromRGB(241, 199, 74), Enum.Material.WoodPlanks, { CanCollide = false })
    WorldBuilder.MakePart(folder, "MiddleArrowHead", Vector3.new(7, 0.6, 7), baseFrame * CFrame.new(-16, 1.5, -29), Color3.fromRGB(241, 199, 74), Enum.Material.WoodPlanks, { CanCollide = false })
    WorldBuilder.MakePart(folder, "CenterArrowStem", Vector3.new(4, 0.6, 9), baseFrame * CFrame.new(16, 1.5, -23), VisualKit.Global.Emerald, Enum.Material.WoodPlanks, { CanCollide = false })
    WorldBuilder.MakePart(folder, "CenterArrowHead", Vector3.new(7, 0.6, 7), baseFrame * CFrame.new(16, 1.5, -29), VisualKit.Global.Emerald, Enum.Material.WoodPlanks, { CanCollide = false })
    local middleBeacon = WorldBuilder.MakePart(folder, "MiddleBeacon", Vector3.new(3.2, 12, 3.2), baseFrame * CFrame.new(-16, 7, -38), Color3.fromRGB(241, 199, 74), Enum.Material.SmoothPlastic, {
        Transparency = 0.58,
        CanCollide = false,
    })
    local centerBeacon = WorldBuilder.MakePart(folder, "CenterBeacon", Vector3.new(3.4, 16, 3.4), baseFrame * CFrame.new(16, 9, -38), VisualKit.Global.Emerald, Enum.Material.SmoothPlastic, {
        Transparency = 0.54,
        CanCollide = false,
    })
    WorldBuilder.AddPointLight(middleBeacon, Color3.fromRGB(241, 199, 74), 0.12, {
        Range = 13,
        Category = "ReadabilitySupport",
    })
    WorldBuilder.AddPointLight(centerBeacon, VisualKit.Global.Emerald, 0.18, {
        Range = 16,
        Category = "ReadabilitySupport",
    })

    local spawnPosition = transformOffset(baseFrame, layout.SpawnOffset)
    local spawn = makeSpawn(folder, "Spawn", getFacingFrame(spawnPosition, transformOffset(baseFrame, layout.CoreOffset)), teamConfig.Color, false, teamConfig.Color)
    ArenaState.RegisterTeamSpawn(teamConfig.Id, spawn)
    WorldBuilder.MakePart(folder, "SpawnTrim", Vector3.new(16, 0.8, 16), CFrame.new(spawnPosition + Vector3.new(0, -0.4, 0)), teamConfig.Color:Lerp(Color3.new(1, 1, 1), 0.12), Enum.Material.SmoothPlastic, {
        CanCollide = false,
        Transparency = 0.16,
    })

    local core = WorldBuilder.BuildCore(folder, CFrame.new(transformOffset(baseFrame, layout.CoreOffset)), teamConfig.Color, teamConfig.BiomeId, "Totem do Time")
    core:SetAttribute("CoreTeamId", teamConfig.Id)
    core:SetAttribute("CoreHealth", Config.Match.MaxCoreHealth)
    ArenaState.RegisterCore(teamConfig.Id, core)

    local itemShop = WorldBuilder.BuildShopStand(
        folder,
        "ItemShop",
        getFacingFrame(transformOffset(baseFrame, layout.ShopOffset), transformOffset(baseFrame, layout.RouteFocusOffset)),
        Color3.fromRGB(47, 100, 156),
        "Loja"
    )
    itemShop:SetAttribute("ShopKind", "Items")
    itemShop:SetAttribute("TeamId", teamConfig.Id)
    local itemPrompt = WorldBuilder.AddPrompt(itemShop, "ItemShopPrompt", "Abrir", "Loja")
    WorldRuntime.RegisterPrompt(itemPrompt)
    ArenaState.RegisterShop(teamConfig.Id, "Items", itemShop)

    local upgradeShop = WorldBuilder.BuildShopStand(
        folder,
        "UpgradeShop",
        getFacingFrame(transformOffset(baseFrame, layout.UpgradeOffset), transformOffset(baseFrame, layout.RouteFocusOffset)),
        Color3.fromRGB(116, 79, 168),
        "Upgrades"
    )
    upgradeShop:SetAttribute("ShopKind", "Upgrades")
    upgradeShop:SetAttribute("TeamId", teamConfig.Id)
    local upgradePrompt = WorldBuilder.AddPrompt(upgradeShop, "UpgradeShopPrompt", "Abrir", "Upgrades")
    WorldRuntime.RegisterPrompt(upgradePrompt)
    ArenaState.RegisterShop(teamConfig.Id, "Upgrades", upgradeShop)

    local generatorsFolder = WorldBuilder.MakeFolder(folder, "Generators")

    local ironGenerator = WorldBuilder.BuildGenerator(
        generatorsFolder,
        "BaseIron",
        CFrame.new(transformOffset(baseFrame, layout.IronGeneratorOffset)),
        VisualKit.Global.Iron,
        "Ferro"
    )
    ironGenerator:SetAttribute("GeneratorType", "BaseIron")
    ironGenerator:SetAttribute("TeamId", teamConfig.Id)

    local goldGenerator = WorldBuilder.BuildGenerator(
        generatorsFolder,
        "BaseGold",
        CFrame.new(transformOffset(baseFrame, layout.GoldGeneratorOffset)),
        VisualKit.Global.Gold,
        "Ouro"
    )
    goldGenerator:SetAttribute("GeneratorType", "BaseGold")
    goldGenerator:SetAttribute("TeamId", teamConfig.Id)

    local defensePad = WorldBuilder.MakePart(
        folder,
        "DefensePad",
        Vector3.new(32, 0.6, 24),
        CFrame.new(transformOffset(baseFrame, Vector3.new(0, 1, -2))),
        teamConfig.Color:Lerp(Color3.new(0, 0, 0), 0.18),
        Enum.Material.Ground,
        { Transparency = 0.6 }
    )
    defensePad:SetAttribute("GameplayDecor", true)

    spawn:SetAttribute("GameplaySpawn", true)
end

local function buildCenter(root)
    local centerFolder = WorldBuilder.BuildIsland(root, "Center", WorldData.CenterIsland.Position, WorldData.CenterIsland.Size, CenterKit, {
        Glow = true,
    })

    WorldBuilder.BuildEmeraldShrine(centerFolder, "CenterShrine", CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 5, 0)), VisualKit.Global.Emerald, "Centro")
    local centerSign = WorldBuilder.MakePart(centerFolder, "CenterSign", Vector3.new(28, 4, 1), CFrame.new(WorldData.CenterIsland.Position + Vector3.new(0, 9, -34)), Color3.fromRGB(18, 24, 34), Enum.Material.SmoothPlastic, {
        CanCollide = false,
    })
    WorldBuilder.AddDoubleSurfaceText(centerSign, "Centro de Esmeraldas", VisualKit.Global.TextLight, 22)

    for index, offset in ipairs({
        Vector3.new(44, 8, 34),
        Vector3.new(-44, 8, 34),
        Vector3.new(0, 8, -50),
    }) do
        local beacon = WorldBuilder.MakePart(centerFolder, "EmeraldBeacon" .. index, Vector3.new(6, 18, 6), CFrame.new(WorldData.CenterIsland.Position + offset), VisualKit.Global.Emerald, Enum.Material.SmoothPlastic, {
            Transparency = 0.4,
        })
        WorldBuilder.AddPointLight(beacon, VisualKit.Global.Emerald, 0.18, {
            Range = 14,
            Category = "ReadabilitySupport",
        })
    end

    local generatorsFolder = WorldBuilder.MakeFolder(centerFolder, "Generators")
    for index, position in ipairs(WorldData.CenterEmeraldGenerators) do
        local generator = WorldBuilder.BuildGenerator(
            generatorsFolder,
            string.format("CenterEmerald%d", index),
            CFrame.new(WorldData.CenterIsland.Position + position),
            VisualKit.Global.Emerald,
            "Esmeralda"
        )
        generator:SetAttribute("GeneratorType", "MidEmerald")
    end

    for index, angle in ipairs({ 30, 150, 270 }) do
        local radians = math.rad(angle)
        local routeFrame = CFrame.lookAt(
            WorldData.CenterIsland.Position + Vector3.new(math.cos(radians) * 46, 1.2, math.sin(radians) * 46),
            WorldData.CenterIsland.Position
        )
        WorldBuilder.BuildRouteMouth(centerFolder, "CenterApproach" .. index, routeFrame, VisualKit.Global.Emerald, "Construa")
    end
end

local function buildMidIslands(root)
    local folder = WorldBuilder.MakeFolder(root, "MidIslands")
    for _, island in ipairs(WorldData.MidIslands) do
        local islandFolder = WorldBuilder.BuildIsland(folder, island.Id, island.Position, island.Size, CenterKit, {
            Glow = island.ActiveDuelLane == true,
        })
        islandFolder:SetAttribute("ActiveDuelLane", island.ActiveDuelLane == true)
        local islandFrame = getFacingFrame(island.Position, WorldData.CenterIsland.Position)
        WorldBuilder.BuildEmeraldShrine(islandFolder, island.Id .. "Shrine", CFrame.new(island.Position + Vector3.new(0, 2.5, 0)), VisualKit.Global.Emerald, "Ilha do Meio")
        WorldBuilder.BuildRouteMouth(islandFolder, "MidBaseApproach", islandFrame * CFrame.new(-10, 1.2, 12), Color3.fromRGB(129, 116, 96), "Base")
        WorldBuilder.BuildRouteMouth(islandFolder, "MidCenterApproach", islandFrame * CFrame.new(10, 1.2, -14), VisualKit.Global.Emerald, "Centro")
        if island.ActiveDuelLane == true then
            WorldBuilder.MakePart(islandFolder, "DuelLaneMarker", Vector3.new(24, 0.6, 4), islandFrame * CFrame.new(0, 2.1, -20), Config.UI.Theme.AccentColor, Enum.Material.SmoothPlastic, {
                Transparency = 0.28,
                CanCollide = false,
            })
        end
        local middleTrigger = WorldBuilder.MakePart(
            islandFolder,
            "MiddleTrigger",
            Vector3.new(20, 8, 20),
            CFrame.new(island.Position + Vector3.new(0, 6, 0)),
            VisualKit.Global.Emerald,
            Enum.Material.SmoothPlastic,
            { Transparency = 1, CanCollide = false, CastShadow = false }
        )
        middleTrigger:SetAttribute("MiddleIslandTrigger", true)
        WorldRuntime.RegisterMiddleTrigger(middleTrigger)

        local generator = WorldBuilder.BuildGenerator(
            islandFolder,
            island.Id .. "Generator",
            CFrame.new(island.Position + Vector3.new(0, 2.5, 0)),
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
    WorldBuilder.AddDoubleSurfaceText(deckSign, "Espectador", VisualKit.Global.TextLight, 24)
    ArenaState.RegisterSpectatorSpawn(spectatorSpawn)
end

local function buildArenaBackdrop(root)
    local backdrop = WorldBuilder.MakeFolder(root, "Backdrop")
    for index, angle in ipairs({ 0, 60, 120, 180, 240, 300 }) do
        local radians = math.rad(angle)
        local position = Vector3.new(math.cos(radians) * 360, -6, math.sin(radians) * 360)
        local wall = WorldBuilder.MakePart(
            backdrop,
            "BackdropWall" .. tostring(index),
            Vector3.new(120, 58, 12),
            CFrame.new(position) * CFrame.Angles(0, radians, 0),
            VisualKit.Global.VoidColor,
            Enum.Material.Slate,
            { Transparency = 0.06 }
        )
        WorldBuilder.AddPointLight(wall, Config.UI.Theme.AccentColor, 0.12, {
            Range = 36,
            Category = "PureDecor",
        })
    end

    WorldBuilder.MakePart(
        backdrop,
        "VoidFloor",
        Vector3.new(860, 12, 860),
        CFrame.new(0, -34, 0),
        VisualKit.Global.VoidColor:Lerp(Color3.new(0, 0, 0), 0.18),
        Enum.Material.Slate,
        { Transparency = 0.14 }
    )
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
