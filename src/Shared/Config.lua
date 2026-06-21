local Config = {
    Areas = {
        Hub = {
            Name = "Hub",
            DisplayName = "Hub Central",
            AccentColor = Color3.fromRGB(0, 255, 255),
            Position = Vector3.new(0, 0, 0),
        },
        Arena = {
            Name = "Arena",
            DisplayName = "Arena de Moedas",
            AccentColor = Color3.fromRGB(255, 196, 0),
            Position = Vector3.new(0, 0, 115),
        },
        Parkour = {
            Name = "Parkour",
            DisplayName = "Pista Parkour",
            AccentColor = Color3.fromRGB(0, 255, 127),
            Position = Vector3.new(-120, 0, 0),
        },
        Shop = {
            Name = "Shop",
            DisplayName = "Loja Cosmetica",
            AccentColor = Color3.fromRGB(255, 105, 180),
            Position = Vector3.new(120, 0, 0),
        },
        Leaderboard = {
            Name = "Leaderboard",
            DisplayName = "Top Coins",
            AccentColor = Color3.fromRGB(170, 85, 255),
            Position = Vector3.new(0, 0, -120),
        },
        Portals = {
            Name = "Portals",
            DisplayName = "Portais",
            AccentColor = Color3.fromRGB(255, 255, 255),
            Position = Vector3.new(0, 0, 0),
        },
    },

    PortalTargets = {
        Hub = "Hub",
        Arena = "Arena",
        Parkour = "Parkour",
        Shop = "Shop",
        Leaderboard = "Leaderboard",
    },

    RoundDurationSeconds = 60,

    Coin = {
        Value = 5,
        Count = 12,
        Radius = 32,
        Height = 4,
        RespawnSeconds = 8,
        Color = Color3.fromRGB(255, 221, 50),
        Material = Enum.Material.Neon,
    },

    ShopItems = {
        SparkTrail = {
            DisplayName = "Spark Trail",
            Price = 20,
            TintColor = Color3.fromRGB(0, 255, 255),
        },
        VictoryGlow = {
            DisplayName = "Victory Glow",
            Price = 40,
            TintColor = Color3.fromRGB(255, 196, 0),
        },
        PinkPulse = {
            DisplayName = "Pink Pulse",
            Price = 60,
            TintColor = Color3.fromRGB(255, 105, 180),
        },
    },

    UI = {
        Title = "CS Fan Zone",
        Theme = {
            BackgroundColor = Color3.fromRGB(15, 18, 30),
            AccentColor = Color3.fromRGB(0, 255, 255),
            SecondaryAccentColor = Color3.fromRGB(255, 105, 180),
            TextColor = Color3.fromRGB(245, 245, 245),
            MutedTextColor = Color3.fromRGB(180, 190, 210),
            SuccessColor = Color3.fromRGB(90, 255, 180),
            WarningColor = Color3.fromRGB(255, 205, 80),
            ErrorColor = Color3.fromRGB(255, 110, 120),
        },
        PortalButtons = { "Hub", "Arena", "Parkour", "Shop" },
        ShopButtonLabel = "Loja",
        TimerLabelPrefix = "Rodada",
    },

    Audio = {
        CoinCollectSoundId = "rbxassetid://0",
        RoundStartSoundId = "rbxassetid://0",
        RoundEndSoundId = "rbxassetid://0",
        TeleportSoundId = "rbxassetid://0",
    },
}

return Config
