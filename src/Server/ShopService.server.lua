local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))
local ToolFactory = require(script.Parent:WaitForChild("ToolFactory"))

local remotes = Remotes.GetAll()

local function getItemById(itemId)
    for _, item in ipairs(Config.Shop.Items) do
        if item.Id == itemId then
            return item
        end
    end
    return nil
end

remotes.PurchaseRequested.OnServerEvent:Connect(function(player, payload)
    if typeof(payload) ~= "table" or typeof(payload.ItemId) ~= "string" then
        return
    end

    local item = getItemById(payload.ItemId)
    if not item then
        return
    end

    local shopPart = ArenaState.GetShopPart(player, "Items")
    local ok, reason = ArenaState.CanUseShop(player, shopPart)
    if not ok then
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = reason or Config.UI.Messages.PurchaseDenied,
        })
        return
    end

    if not ArenaState.CanAfford(player, item.ResourceType, item.Cost) then
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = Config.UI.Messages.InsufficientFunds,
            ItemId = item.Id,
        })
        return
    end

    if not ArenaState.SpendResource(player, item.ResourceType, item.Cost) then
        return
    end

    local granted, err = ToolFactory.GrantItem(player, item)
    if not granted then
        ArenaState.AddResource(player, item.ResourceType, item.Cost)
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = err or Config.UI.Messages.DeliveryFailed,
            ItemId = item.Id,
        })
        return
    end

    ArenaState.PushFeedback(player, "PurchaseSuccess", {
        ItemId = item.Id,
        DisplayName = item.DisplayName,
        Message = string.format(Config.UI.Messages.PurchaseSuccess, item.DisplayName),
    })
    ArenaState.MarkStarterPurchase(player, item.Id)
    if item.Id == Config.UI.StarterFlow.First or item.Id == Config.UI.StarterFlow.Second or item.Id == Config.UI.StarterFlow.Third then
        ArenaState.PushFeedback(player, "FirstStarterPurchase", {
            ItemId = item.Id,
            DisplayName = item.DisplayName,
        })
    end
end)
