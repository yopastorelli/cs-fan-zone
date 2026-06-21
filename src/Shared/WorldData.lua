local WorldData = {}

WorldData.AreasInOrder = {
    "CentralPlaza",
    "NostalgiaWall",
    "ClipStage",
    "MemeLounge",
    "FinalCelebrationRoom",
}

WorldData.Paths = {
    {
        Name = "SeasonPath",
        From = Vector3.new(-45, 0, 0),
        To = Vector3.new(-91, 0, 0),
        Area = "CentralPlaza",
        ColorArea = "NostalgiaWall",
    },
    {
        Name = "ChaosPath",
        From = Vector3.new(0, 0, 45),
        To = Vector3.new(0, 0, 91),
        Area = "CentralPlaza",
        ColorArea = "ClipStage",
    },
    {
        Name = "MemePath",
        From = Vector3.new(45, 0, 0),
        To = Vector3.new(91, 0, 0),
        Area = "CentralPlaza",
        ColorArea = "MemeLounge",
    },
    {
        Name = "SecretPath",
        From = Vector3.new(0, 0, -45),
        To = Vector3.new(0, 0, -100),
        Area = "CentralPlaza",
        ColorArea = "FinalCelebrationRoom",
    },
}

WorldData.Landmarks = {
    {
        Id = "portal_temporadas",
        Area = "NostalgiaWall",
        Type = "portal",
        Name = "Portal das Temporadas",
        Position = Vector3.new(-125, 12, 18),
        Size = Vector3.new(24, 24, 4),
        AccentColor = Color3.fromRGB(255, 203, 75),
        Text = "Cada era muda o palco, mas a energia do grupo continua.",
    },
    {
        Id = "arena_caos",
        Area = "ClipStage",
        Type = "arena",
        Name = "Arena do Caos",
        Position = Vector3.new(0, 4, 136),
        Size = Vector3.new(38, 8, 38),
        AccentColor = Color3.fromRGB(255, 95, 160),
        Text = "Aqui a gritaria e a estrategia sempre dividem o mesmo espaco.",
    },
    {
        Id = "galeria_arquetipos",
        Area = "CentralPlaza",
        Type = "gallery",
        Name = "Galeria dos Arquetipos",
        Position = Vector3.new(-34, 6, 16),
        Size = Vector3.new(24, 12, 8),
        AccentColor = Color3.fromRGB(0, 255, 220),
        Text = "Nenhum nome, muitos papeis: todo fandom entende o elenco sem legenda.",
    },
    {
        Id = "laboratorio_pegadinhas",
        Area = "MemeLounge",
        Type = "lab",
        Name = "Laboratorio das Pegadinhas",
        Position = Vector3.new(125, 5, -18),
        Size = Vector3.new(28, 10, 20),
        AccentColor = Color3.fromRGB(100, 245, 145),
        Text = "Portas falsas, respostas rapidas e humor calibrado para o caos certo.",
    },
    {
        Id = "mirante_selfie",
        Area = "FinalCelebrationRoom",
        Type = "photo",
        Name = "Mirante da Selfie",
        Position = Vector3.new(0, 6, -152),
        Size = Vector3.new(32, 12, 6),
        AccentColor = Color3.fromRGB(160, 115, 255),
        Text = "Se a jornada valeu, esse e o quadro que sobra na memoria.",
    },
    {
        Id = "camara_secreta",
        Area = "FinalCelebrationRoom",
        Type = "secret",
        Name = "Camara Secreta",
        Position = Vector3.new(0, 5, -130),
        Size = Vector3.new(30, 10, 20),
        AccentColor = Color3.fromRGB(138, 92, 255),
        Text = "O segredo final nao diz de quem e, mas todo fa entende a promessa.",
    },
}

WorldData.LoreSigns = {
    { Id = "season_board_01", Area = "NostalgiaWall", Position = Vector3.new(-155, 7, -20), Text = "Temporadas passam. O ritual de reunir o grupo permanece." },
    { Id = "season_board_02", Area = "NostalgiaWall", Position = Vector3.new(-139, 7, -20), Text = "Toda fase boa mistura disputa, improviso e memoria compartilhada." },
    { Id = "season_board_03", Area = "NostalgiaWall", Position = Vector3.new(-123, 7, -20), Text = "Algumas historias parecem internas demais para precisar de explicacao." },
    { Id = "chaos_board_01", Area = "ClipStage", Position = Vector3.new(-18, 8, 90), Text = "Quando o grupo entra em cena, o caos vira coreografia." },
    { Id = "meme_board_01", Area = "MemeLounge", Position = Vector3.new(106, 7, -36), Text = "Toda comunidade forte tem seu proprio alfabeto de piadas e sustos." },
    { Id = "secret_board_01", Area = "FinalCelebrationRoom", Position = Vector3.new(0, 8, -108), Text = "Quem chega ate aqui nao quer explicacao. Quer o momento certo." },
}

WorldData.Archetypes = {
    { Id = "builder", Name = "O Construtor", Area = "CentralPlaza", Position = Vector3.new(-46, 4, 16), Color = Color3.fromRGB(0, 255, 220), Text = "Transforma mapa em palco e palco em historia." },
    { Id = "rival", Name = "O Rival", Area = "ClipStage", Position = Vector3.new(-32, 4, 132), Color = Color3.fromRGB(255, 95, 160), Text = "Toda rivalidade aqui e sobre timing, nao sobre rancor." },
    { Id = "chaotic", Name = "O Caotico", Area = "MemeLounge", Position = Vector3.new(146, 4, -8), Color = Color3.fromRGB(100, 245, 145), Text = "A melhor ideia ruim sempre chega primeiro." },
    { Id = "strategist", Name = "O Estrategista", Area = "NostalgiaWall", Position = Vector3.new(-108, 4, 24), Color = Color3.fromRGB(255, 203, 75), Text = "Observa antes, age depois, e quase sempre esta um passo a frente." },
    { Id = "explorer", Name = "O Explorador", Area = "FinalCelebrationRoom", Position = Vector3.new(-20, 4, -140), Color = Color3.fromRGB(160, 115, 255), Text = "Procura a pista que o resto do grupo deixou para tras." },
    { Id = "guardian", Name = "O Guardiao", Area = "CentralPlaza", Position = Vector3.new(46, 4, 16), Color = Color3.fromRGB(90, 255, 170), Text = "Cuida do clima do grupo enquanto o caos acontece ao redor." },
}

WorldData.PrankPuzzle = {
    Switches = {
        { Id = "switch_alpha", Position = Vector3.new(110, 5, 14), Color = Color3.fromRGB(0, 255, 220) },
        { Id = "switch_beta", Position = Vector3.new(125, 5, 24), Color = Color3.fromRGB(255, 203, 75) },
        { Id = "switch_gamma", Position = Vector3.new(140, 5, 14), Color = Color3.fromRGB(255, 95, 160) },
    },
    SafePlatformPosition = Vector3.new(125, 2, 34),
    FakePlatformPositions = {
        Vector3.new(106, 2, 34),
        Vector3.new(144, 2, 34),
    },
}

WorldData.PhotoSpot = {
    Name = "SelfieSpot",
    Position = Vector3.new(0, 4, -166),
    Size = Vector3.new(18, 1, 12),
    Message = "Enquadre o grupo imaginario e deixe a luz fazer o resto.",
}

WorldData.FinalRoomAccess = {
    TargetPosition = Vector3.new(0, 4, -144),
}

return WorldData
