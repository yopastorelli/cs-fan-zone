local WorldData = {}

WorldData.CenterIsland = {
    Position = Vector3.new(0, 0, 0),
    Size = Vector3.new(88, 6, 88),
}

WorldData.MidIslands = {
    { Id = "mid_planicie", Position = Vector3.new(0, 0, -112), Size = Vector3.new(30, 4, 30) },
    { Id = "mid_deserto", Position = Vector3.new(97, 0, -56), Size = Vector3.new(30, 4, 30) },
    { Id = "mid_taiga", Position = Vector3.new(97, 0, 56), Size = Vector3.new(30, 4, 30) },
    { Id = "mid_selva", Position = Vector3.new(0, 0, 112), Size = Vector3.new(30, 4, 30) },
    { Id = "mid_neve", Position = Vector3.new(-97, 0, 56), Size = Vector3.new(30, 4, 30) },
    { Id = "mid_cogumelos", Position = Vector3.new(-97, 0, -56), Size = Vector3.new(30, 4, 30) },
}

WorldData.BaseLayout = {
    IslandSize = Vector3.new(74, 6, 74),
    SpawnOffset = Vector3.new(0, 3, 18),
    CoreOffset = Vector3.new(0, 4, -2),
    ShopOffset = Vector3.new(-18, 3, 14),
    UpgradeOffset = Vector3.new(18, 3, 14),
    IronGeneratorOffset = Vector3.new(-6, 2.5, 2),
    GoldGeneratorOffset = Vector3.new(6, 2.5, 2),
}

WorldData.CenterEmeraldGenerators = {
    Vector3.new(18, 4, 0),
    Vector3.new(-18, 4, 0),
    Vector3.new(0, 4, 18),
    Vector3.new(0, 4, -18),
}

WorldData.SpectatorDeck = {
    Position = Vector3.new(0, 26, 0),
    Size = Vector3.new(42, 2, 42),
}

WorldData.Lobby = {
    Position = Vector3.new(0, 0, 318),
    WalkwayPosition = Vector3.new(0, 1, 224),
    ViewDeckPosition = Vector3.new(0, 3, 145),
}

return WorldData
