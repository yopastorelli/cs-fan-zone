local Config = {
    Areas = {
        CentralPlaza = {
            Name = "CentralPlaza",
            DisplayName = "Praca Central",
            AccentColor = Color3.fromRGB(0, 255, 220),
            Position = Vector3.new(0, 0, 0),
            Size = Vector3.new(96, 2, 96),
        },
        NostalgiaWall = {
            Name = "NostalgiaWall",
            DisplayName = "Mural da Nostalgia",
            AccentColor = Color3.fromRGB(255, 203, 75),
            Position = Vector3.new(-125, 0, 0),
            Size = Vector3.new(70, 2, 82),
        },
        ClipStage = {
            Name = "ClipStage",
            DisplayName = "Palco dos Clipes",
            AccentColor = Color3.fromRGB(255, 95, 160),
            Position = Vector3.new(0, 0, 125),
            Size = Vector3.new(84, 2, 70),
        },
        MemeLounge = {
            Name = "MemeLounge",
            DisplayName = "Lounge dos Memes",
            AccentColor = Color3.fromRGB(100, 245, 145),
            Position = Vector3.new(125, 0, 0),
            Size = Vector3.new(74, 2, 82),
        },
        FinalCelebrationRoom = {
            Name = "FinalCelebrationRoom",
            DisplayName = "Sala Final",
            AccentColor = Color3.fromRGB(160, 115, 255),
            Position = Vector3.new(0, 0, -130),
            Size = Vector3.new(74, 2, 62),
        },
    },

    Mission = {
        CollectibleGoal = 12,
        PoiGoal = 3,
        ObjectiveText = "Encontre 12 memorias e ative 3 pontos de nostalgia.",
        StartMessage = "Explore o hub e registre as memorias escondidas.",
        DuplicateCollectibleMessage = "Essa memoria ja foi registrada.",
        DuplicatePoiMessage = "Esse ponto ja foi ativado.",
        CompletionMessage = "Circuito completo. A Sala Final foi desbloqueada.",
        PhotoPromptMessage = "Tudo pronto para o print final.",
        BlockedFinalRoomMessage = "Complete 12 memorias e 3 POIs para entrar na Sala Final.",
        FinalRoomPromptText = "Entrar",
    },

    Collectibles = {
        { Id = "memory_01", DisplayName = "Ingresso Neon", Area = "CentralPlaza", Position = Vector3.new(-26, 4, -18), Color = Color3.fromRGB(0, 255, 220) },
        { Id = "memory_02", DisplayName = "Adesivo Pixel", Area = "CentralPlaza", Position = Vector3.new(24, 4, -20), Color = Color3.fromRGB(255, 203, 75) },
        { Id = "memory_03", DisplayName = "Botao Replay", Area = "CentralPlaza", Position = Vector3.new(8, 4, 28), Color = Color3.fromRGB(255, 95, 160) },
        { Id = "memory_04", DisplayName = "Poster Ficticio", Area = "NostalgiaWall", Position = Vector3.new(-142, 4, -24), Color = Color3.fromRGB(255, 203, 75) },
        { Id = "memory_05", DisplayName = "Cartao Antigo", Area = "NostalgiaWall", Position = Vector3.new(-116, 4, 18), Color = Color3.fromRGB(255, 230, 120) },
        { Id = "memory_06", DisplayName = "Luz de Palco", Area = "ClipStage", Position = Vector3.new(-26, 4, 116), Color = Color3.fromRGB(255, 95, 160) },
        { Id = "memory_07", DisplayName = "Mini Trofeu", Area = "ClipStage", Position = Vector3.new(0, 8, 146), Color = Color3.fromRGB(255, 220, 90) },
        { Id = "memory_08", DisplayName = "Pulseira VIP", Area = "ClipStage", Position = Vector3.new(28, 4, 118), Color = Color3.fromRGB(0, 255, 220) },
        { Id = "memory_09", DisplayName = "Cubo Meme", Area = "MemeLounge", Position = Vector3.new(106, 4, -24), Color = Color3.fromRGB(100, 245, 145) },
        { Id = "memory_10", DisplayName = "Almofada Reacao", Area = "MemeLounge", Position = Vector3.new(146, 4, 8), Color = Color3.fromRGB(150, 255, 180) },
        { Id = "memory_11", DisplayName = "Placa Secreta", Area = "MemeLounge", Position = Vector3.new(120, 4, 30), Color = Color3.fromRGB(255, 95, 160) },
        { Id = "memory_12", DisplayName = "Chave da Celebracao", Area = "CentralPlaza", Position = Vector3.new(0, 4, -42), Color = Color3.fromRGB(160, 115, 255) },
    },

    POIs = {
        {
            Id = "poi_nostalgia_wall",
            DisplayName = "Mural da Nostalgia",
            Area = "NostalgiaWall",
            Position = Vector3.new(-125, 6, -35),
            PromptText = "Ler mural",
            Message = "Voce ativou o mural: memorias boas ficam melhores quando viram historias novas.",
        },
        {
            Id = "poi_clip_stage",
            DisplayName = "Palco dos Clipes",
            Area = "ClipStage",
            Position = Vector3.new(0, 7, 100),
            PromptText = "Acender palco",
            Message = "O palco acendeu: todo grande momento comeca como um teste pequeno.",
        },
        {
            Id = "poi_meme_lounge",
            DisplayName = "Lounge dos Memes",
            Area = "MemeLounge",
            Position = Vector3.new(125, 6, -34),
            PromptText = "Abrir painel",
            Message = "Painel ativado: humor original, sem copiar nomes, logos ou imagens reais.",
        },
    },

    UI = {
        Title = "CS Fan Zone",
        CollectiblesLabel = "Memorias",
        PoiLabel = "POIs",
        StatusLabel = "Ritual",
        Theme = {
            BackgroundColor = Color3.fromRGB(16, 20, 28),
            PanelColor = Color3.fromRGB(24, 30, 42),
            AccentColor = Color3.fromRGB(0, 255, 220),
            SecondaryAccentColor = Color3.fromRGB(255, 203, 75),
            TextColor = Color3.fromRGB(245, 248, 255),
            MutedTextColor = Color3.fromRGB(182, 194, 210),
            SuccessColor = Color3.fromRGB(96, 255, 170),
            WarningColor = Color3.fromRGB(255, 205, 80),
            SecretGlowColor = Color3.fromRGB(255, 255, 255),
        },
    },

    Audio = {
        CollectSoundId = "rbxassetid://0",
        PoiSoundId = "rbxassetid://0",
        CompletionSoundId = "rbxassetid://0",
    },

    Compliance = {
        MaturityTarget = "Minimal",
        AllowRealNames = false,
        AllowLogos = false,
        AllowRecognizableLikeness = false,
        AllowRecognizableSlogans = false,
        AllowOffPlatformLinks = false,
        AssetRegisterPath = "docs/asset-register.md",
    },
}

return Config
