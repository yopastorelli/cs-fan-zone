local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local world = Workspace:WaitForChild("CSFanZone")
local arena = world:WaitForChild(Config.Areas.Arena.Name)
local coinCenter = arena:WaitForChild("CoinCenter")

local coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = arena

local touchDebounces = {}

local function getPlayerFromHit(hit)
    local character = hit and hit.Parent
    if not character then
        return nil
    end

    return Players:GetPlayerFromCharacter(character)
end

local function getCoinsStat(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    return leaderstats and leaderstats:FindFirstChild("Coins")
end

local function updateRoundCoins(player)
    local current = player:GetAttribute("RoundCoins") or 0
    player:SetAttribute("RoundCoins", current + Config.Coin.Value)
end

local function setCoinVisible(coin, isVisible)
    coin.Transparency = isVisible and 0 or 1
    coin.CanTouch = isVisible
    coin.CanQuery = isVisible

    local prompt = coin:FindFirstChild("CollectBillboard")
    if prompt then
        prompt.Enabled = isVisible
    end
end

local function respawnCoin(coin)
    task.delay(Config.Coin.RespawnSeconds, function()
        if coin.Parent then
            setCoinVisible(coin, true)
        end
    end)
end

local function onCoinTouched(coin, hit)
    if touchDebounces[coin] then
        return
    end

    local player = getPlayerFromHit(hit)
    if not player then
        return
    end

    local coins = getCoinsStat(player)
    if not coins then
        return
    end

    touchDebounces[coin] = true

    coins.Value += Config.Coin.Value
    updateRoundCoins(player)
    setCoinVisible(coin, false)
    respawnCoin(coin)

    task.delay(0.5, function()
        touchDebounces[coin] = nil
    end)
end

for coinIndex = 1, Config.Coin.Count do
    local angle = (math.pi * 2 / Config.Coin.Count) * coinIndex
    local position = coinCenter.Position
        + Vector3.new(math.cos(angle) * Config.Coin.Radius, 0, math.sin(angle) * Config.Coin.Radius)

    local coin = Instance.new("Part")
    coin.Name = "Coin" .. coinIndex
    coin.Shape = Enum.PartType.Ball
    coin.Size = Vector3.new(3, 3, 3)
    coin.Position = position
    coin.Anchored = true
    coin.Color = Config.Coin.Color
    coin.Material = Config.Coin.Material
    coin.Parent = coinFolder

    local light = Instance.new("PointLight")
    light.Color = Config.Coin.Color
    light.Range = 10
    light.Brightness = 2
    light.Parent = coin

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CollectBillboard"
    billboard.Size = UDim2.fromOffset(90, 36)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = coin

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(18, 22, 36)
    text.BackgroundTransparency = 0.2
    text.Font = Enum.Font.GothamBold
    text.Text = "+" .. tostring(Config.Coin.Value)
    text.TextScaled = true
    text.TextColor3 = Color3.fromRGB(18, 18, 18)
    text.Parent = billboard

    coin.Touched:Connect(function(hit)
        onCoinTouched(coin, hit)
    end)
end
