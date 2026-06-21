local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local requestPurchase = Remotes.GetRemote("RequestPurchase")
local requestEquip = Remotes.GetRemote("RequestEquip")
local shopStateUpdated = Remotes.GetRemote("ShopStateUpdated")

local playerInventory = {}

local function serializeOwnedItems(ownedLookup)
    local ownedItems = {}

    for itemName in pairs(ownedLookup) do
        ownedItems[#ownedItems + 1] = itemName
    end

    table.sort(ownedItems)
    return ownedItems, table.concat(ownedItems, ",")
end

local function getCoinsStat(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    return leaderstats and leaderstats:FindFirstChild("Coins")
end

local function applyCosmetic(player, itemName)
    local character = player.Character
    if not character then
        return
    end

    local highlight = character:FindFirstChild("CosmeticHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "CosmeticHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.65
        highlight.OutlineTransparency = 0.15
        highlight.Parent = character
    end

    if itemName == "None" then
        highlight.Enabled = false
        return
    end

    local item = Config.ShopItems[itemName]
    if not item then
        highlight.Enabled = false
        return
    end

    highlight.Enabled = true
    highlight.FillColor = item.TintColor
    highlight.OutlineColor = item.TintColor
end

local function sendShopState(player, statusMessage)
    local inventory = playerInventory[player]
    if not inventory then
        return
    end

    local ownedItems = serializeOwnedItems(inventory.Owned)
    local coins = getCoinsStat(player)

    shopStateUpdated:FireClient(player, {
        OwnedItems = ownedItems,
        Equipped = inventory.Equipped,
        Coins = coins and coins.Value or 0,
        Message = statusMessage,
    })
end

local function ensureInventory(player)
    if playerInventory[player] then
        return playerInventory[player]
    end

    playerInventory[player] = {
        Owned = {},
        Equipped = "None",
    }

    player:SetAttribute("OwnedCosmetics", "")
    player:SetAttribute("EquippedCosmetic", "None")
    return playerInventory[player]
end

local function updateAttributes(player)
    local inventory = ensureInventory(player)
    local ownedItems, ownedText = serializeOwnedItems(inventory.Owned)

    player:SetAttribute("OwnedCosmetics", ownedText)
    player:SetAttribute("EquippedCosmetic", inventory.Equipped)
    applyCosmetic(player, inventory.Equipped)

    return ownedItems
end

requestPurchase.OnServerEvent:Connect(function(player, itemName)
    local item = Config.ShopItems[itemName]
    if not item then
        sendShopState(player, "Item invalido.")
        return
    end

    local inventory = ensureInventory(player)
    if inventory.Owned[itemName] then
        sendShopState(player, "Item ja adquirido.")
        return
    end

    local coins = getCoinsStat(player)
    if not coins or coins.Value < item.Price then
        sendShopState(player, "Coins insuficientes.")
        return
    end

    coins.Value -= item.Price
    inventory.Owned[itemName] = true
    updateAttributes(player)
    sendShopState(player, string.format("%s comprado com sucesso.", item.DisplayName))
end)

requestEquip.OnServerEvent:Connect(function(player, itemName)
    local inventory = ensureInventory(player)

    if itemName == "None" then
        inventory.Equipped = "None"
        updateAttributes(player)
        sendShopState(player, "Cosmetico removido.")
        return
    end

    if not Config.ShopItems[itemName] then
        sendShopState(player, "Item invalido.")
        return
    end

    if not inventory.Owned[itemName] then
        sendShopState(player, "Compre o item antes de equipar.")
        return
    end

    inventory.Equipped = itemName
    updateAttributes(player)
    sendShopState(player, string.format("%s equipado.", Config.ShopItems[itemName].DisplayName))
end)

Players.PlayerAdded:Connect(function(player)
    ensureInventory(player)

    player.CharacterAdded:Connect(function()
        task.defer(function()
            updateAttributes(player)
            sendShopState(player, "Loja pronta.")
        end)
    end)

    task.defer(function()
        sendShopState(player, "Loja pronta.")
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerInventory[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    ensureInventory(player)
end
