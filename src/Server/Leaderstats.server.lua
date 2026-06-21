local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local function getOrCreateStatFolder(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        return leaderstats
    end

    leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    return leaderstats
end

local function getOrCreateIntValue(parent, name)
    local value = parent:FindFirstChild(name)
    if value then
        return value
    end

    value = Instance.new("IntValue")
    value.Name = name
    value.Parent = parent
    return value
end

local function getLeaderboardLabel()
    local world = Workspace:FindFirstChild("CSFanZone")
    if not world then
        return nil
    end

    local boardArea = world:FindFirstChild(Config.Areas.Leaderboard.Name)
    if not boardArea then
        return nil
    end

    local board = boardArea:FindFirstChild("TopCoinsBoard")
    if not board then
        return nil
    end

    local gui = board:FindFirstChild("SurfaceGui")
    if not gui then
        return nil
    end

    return gui:FindFirstChild("TopCoinsLabel")
end

local function updateLeaderboardBoard()
    local label = getLeaderboardLabel()
    if not label then
        return
    end

    local entries = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local leaderstats = player:FindFirstChild("leaderstats")
        local coins = leaderstats and leaderstats:FindFirstChild("Coins")
        table.insert(entries, {
            Name = player.Name,
            Coins = coins and coins.Value or 0,
        })
    end

    table.sort(entries, function(left, right)
        if left.Coins == right.Coins then
            return left.Name < right.Name
        end

        return left.Coins > right.Coins
    end)

    if #entries == 0 then
        label.Text = "Top Coins\nAguardando jogadores..."
        return
    end

    local lines = { "Top Coins" }
    for index = 1, math.min(5, #entries) do
        local entry = entries[index]
        lines[#lines + 1] = string.format("%d. %s - %d", index, entry.Name, entry.Coins)
    end

    label.Text = table.concat(lines, "\n")
end

local function onPlayerAdded(player)
    local leaderstats = getOrCreateStatFolder(player)
    local coins = getOrCreateIntValue(leaderstats, "Coins")
    local wins = getOrCreateIntValue(leaderstats, "Wins")

    coins.Value = 0
    wins.Value = 0

    player:SetAttribute("EquippedCosmetic", "None")
    player:SetAttribute("OwnedCosmetics", "")
    player:SetAttribute("RoundCoins", 0)

    coins.Changed:Connect(updateLeaderboardBoard)
    updateLeaderboardBoard()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(updateLeaderboardBoard)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

updateLeaderboardBoard()
