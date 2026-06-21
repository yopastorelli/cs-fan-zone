local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local roundStateUpdated = Remotes.GetRemote("RoundStateUpdated")
local shopStateUpdated = Remotes.GetRemote("ShopStateUpdated")
local requestPurchase = Remotes.GetRemote("RequestPurchase")
local requestEquip = Remotes.GetRemote("RequestEquip")

local theme = Config.UI.Theme

local existingGui = playerGui:FindFirstChild("CSFanZoneHUD")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CSFanZoneHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local rootFrame = Instance.new("Frame")
rootFrame.Name = "Root"
rootFrame.Size = UDim2.fromOffset(320, 220)
rootFrame.Position = UDim2.fromOffset(20, 20)
rootFrame.BackgroundColor3 = theme.BackgroundColor
rootFrame.BackgroundTransparency = 0.15
rootFrame.Parent = screenGui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 14)
rootCorner.Parent = rootFrame

local stroke = Instance.new("UIStroke")
stroke.Color = theme.AccentColor
stroke.Thickness = 2
stroke.Parent = rootFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.fromOffset(10, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = Config.UI.Title
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = theme.TextColor
title.Parent = rootFrame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0.5, -15, 0, 24)
coinsLabel.Position = UDim2.fromOffset(10, 48)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.TextSize = 18
coinsLabel.TextColor3 = theme.WarningColor
coinsLabel.Text = "Coins: 0"
coinsLabel.Parent = rootFrame

local winsLabel = Instance.new("TextLabel")
winsLabel.Size = UDim2.new(0.5, -15, 0, 24)
winsLabel.Position = UDim2.new(0.5, 5, 0, 48)
winsLabel.BackgroundTransparency = 1
winsLabel.Font = Enum.Font.GothamBold
winsLabel.TextXAlignment = Enum.TextXAlignment.Left
winsLabel.TextSize = 18
winsLabel.TextColor3 = theme.SuccessColor
winsLabel.Text = "Wins: 0"
winsLabel.Parent = rootFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, -20, 0, 28)
timerLabel.Position = UDim2.fromOffset(10, 82)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 20
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.TextColor3 = theme.AccentColor
timerLabel.Text = "Rodada: --"
timerLabel.Parent = rootFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -20, 0, 40)
messageLabel.Position = UDim2.fromOffset(10, 114)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextWrapped = true
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextSize = 16
messageLabel.TextColor3 = theme.MutedTextColor
messageLabel.Text = "Explore o hub e prepare-se para coletar moedas."
messageLabel.Parent = rootFrame

local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.fromOffset(84, 32)
shopButton.Position = UDim2.new(1, -94, 1, -42)
shopButton.BackgroundColor3 = theme.SecondaryAccentColor
shopButton.Font = Enum.Font.GothamBold
shopButton.Text = Config.UI.ShopButtonLabel
shopButton.TextColor3 = theme.TextColor
shopButton.TextSize = 16
shopButton.Parent = rootFrame

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopButton

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.fromOffset(320, 340)
shopFrame.Position = UDim2.fromOffset(360, 20)
shopFrame.BackgroundColor3 = theme.BackgroundColor
shopFrame.BackgroundTransparency = 0.1
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopFrameCorner = Instance.new("UICorner")
shopFrameCorner.CornerRadius = UDim.new(0, 14)
shopFrameCorner.Parent = shopFrame

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = theme.SecondaryAccentColor
shopStroke.Thickness = 2
shopStroke.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -20, 0, 28)
shopTitle.Position = UDim2.fromOffset(10, 10)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 22
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.TextColor3 = theme.TextColor
shopTitle.Text = "Loja Cosmetica"
shopTitle.Parent = shopFrame

local shopMessage = Instance.new("TextLabel")
shopMessage.Size = UDim2.new(1, -20, 0, 32)
shopMessage.Position = UDim2.fromOffset(10, 42)
shopMessage.BackgroundTransparency = 1
shopMessage.Font = Enum.Font.Gotham
shopMessage.TextWrapped = true
shopMessage.TextXAlignment = Enum.TextXAlignment.Left
shopMessage.TextSize = 15
shopMessage.TextColor3 = theme.MutedTextColor
shopMessage.Text = "Selecione um item."
shopMessage.Parent = shopFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(28, 28)
closeButton.Position = UDim2.new(1, -38, 0, 10)
closeButton.BackgroundColor3 = theme.ErrorColor
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = theme.TextColor
closeButton.TextSize = 16
closeButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local itemsFrame = Instance.new("ScrollingFrame")
itemsFrame.Name = "ItemsFrame"
itemsFrame.Size = UDim2.new(1, -20, 0, 240)
itemsFrame.Position = UDim2.fromOffset(10, 82)
itemsFrame.BackgroundTransparency = 1
itemsFrame.BorderSizePixel = 0
itemsFrame.CanvasSize = UDim2.new()
itemsFrame.ScrollBarThickness = 6
itemsFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
itemsFrame.Parent = shopFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = itemsFrame
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local itemButtons = {}
local state = {
    Owned = {},
    Equipped = "None",
}

local function getSortedShopItemNames()
    local names = {}
    for itemName in pairs(Config.ShopItems) do
        names[#names + 1] = itemName
    end

    table.sort(names)
    return names
end

local function updateOwnedLookup(ownedItems)
    state.Owned = {}
    for _, itemName in ipairs(ownedItems or {}) do
        state.Owned[itemName] = true
    end
end

local function updateShopButtons()
    for itemName, button in pairs(itemButtons) do
        local item = Config.ShopItems[itemName]
        local owned = state.Owned[itemName]
        local isEquipped = state.Equipped == itemName

        if isEquipped then
            button.Text = string.format("%s\nEquipado", item.DisplayName)
            button.BackgroundColor3 = theme.SuccessColor
        elseif owned then
            button.Text = string.format("%s\nEquipar", item.DisplayName)
            button.BackgroundColor3 = item.TintColor
        else
            button.Text = string.format("%s\n%d coins", item.DisplayName, item.Price)
            button.BackgroundColor3 = item.TintColor
        end
    end
end

for index, itemName in ipairs(getSortedShopItemNames()) do
    local item = Config.ShopItems[itemName]
    local button = Instance.new("TextButton")
    button.Name = itemName
    button.Size = UDim2.new(1, -20, 0, 48)
    button.BackgroundColor3 = item.TintColor
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(18, 18, 18)
    button.TextSize = 16
    button.LayoutOrder = index
    button.Parent = itemsFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        if state.Owned[itemName] then
            requestEquip:FireServer(itemName)
        else
            requestPurchase:FireServer(itemName)
        end
    end)

    itemButtons[itemName] = button
end

local unequipButton = Instance.new("TextButton")
unequipButton.Size = UDim2.new(1, -20, 0, 42)
unequipButton.BackgroundColor3 = theme.AccentColor
unequipButton.Font = Enum.Font.GothamBold
unequipButton.TextColor3 = Color3.fromRGB(18, 18, 18)
unequipButton.TextSize = 16
unequipButton.Text = "Remover cosmetico"
unequipButton.LayoutOrder = #getSortedShopItemNames() + 1
unequipButton.Parent = itemsFrame

local unequipCorner = Instance.new("UICorner")
unequipCorner.CornerRadius = UDim.new(0, 10)
unequipCorner.Parent = unequipButton

unequipButton.MouseButton1Click:Connect(function()
    requestEquip:FireServer("None")
end)

local function updateLeaderstats()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")

    if coins then
        coinsLabel.Text = "Coins: " .. tostring(coins.Value)
    end

    if wins then
        winsLabel.Text = "Wins: " .. tostring(wins.Value)
    end
end

local function connectLeaderstat(name)
    local leaderstats = player:WaitForChild("leaderstats")
    local stat = leaderstats:WaitForChild(name)
    stat.Changed:Connect(updateLeaderstats)
end

roundStateUpdated.OnClientEvent:Connect(function(payload)
    timerLabel.Text = string.format("%s: %ds", Config.UI.TimerLabelPrefix, payload.Remaining or 0)
    messageLabel.Text = payload.Message or ""
end)

shopStateUpdated.OnClientEvent:Connect(function(payload)
    updateOwnedLookup(payload.OwnedItems)
    state.Equipped = payload.Equipped or "None"
    shopMessage.Text = payload.Message or "Selecione um item."
    updateShopButtons()
end)

shopButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = not shopFrame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    itemsFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

connectLeaderstat("Coins")
connectLeaderstat("Wins")
updateLeaderstats()
updateShopButtons()
itemsFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
