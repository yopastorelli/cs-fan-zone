local WorldData = {}

WorldData.CenterIsland = {
    Position = Vector3.new(0, 0, 0),
    Size = Vector3.new(150, 6, 150),
}

WorldData.MidIslands = {
    { Id = "mid_planicie", Position = Vector3.new(0, 0, -138), Size = Vector3.new(52, 4, 52), ActiveDuelLane = true },
    { Id = "mid_deserto", Position = Vector3.new(136, 0, -78), Size = Vector3.new(52, 4, 52) },
    { Id = "mid_taiga", Position = Vector3.new(136, 0, 78), Size = Vector3.new(52, 4, 52) },
    { Id = "mid_selva", Position = Vector3.new(0, 0, 138), Size = Vector3.new(52, 4, 52), ActiveDuelLane = true },
    { Id = "mid_neve", Position = Vector3.new(-136, 0, 78), Size = Vector3.new(52, 4, 52) },
    { Id = "mid_cogumelos", Position = Vector3.new(-136, 0, -78), Size = Vector3.new(52, 4, 52) },
}

WorldData.BaseLayout = {
    IslandSize = Vector3.new(80, 6, 80),
    SpawnOffset = Vector3.new(0, 3, 24),
    CoreOffset = Vector3.new(0, 4, -4),
    ShopOffset = Vector3.new(-18, 3, 10),
    UpgradeOffset = Vector3.new(18, 3, 10),
    IronGeneratorOffset = Vector3.new(-6, 2.5, 10),
    GoldGeneratorOffset = Vector3.new(6, 2.5, 10),
    RouteFocusOffset = Vector3.new(0, 3, -30),
}

WorldData.CenterEmeraldGenerators = {
    Vector3.new(0, 4, -34),
    Vector3.new(30, 4, 18),
    Vector3.new(-30, 4, 18),
}

WorldData.SpectatorDeck = {
    Position = Vector3.new(0, 26, 0),
    Size = Vector3.new(42, 2, 42),
}

WorldData.Lobby = {
    Position = Vector3.new(0, 0, 410),
    WalkwayPosition = Vector3.new(0, 1, 305),
    ViewDeckPosition = Vector3.new(0, 3, 215),
}

return WorldData
