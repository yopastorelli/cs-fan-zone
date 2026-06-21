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

local function openShop(player, kind)
    remotes.ShopOpened:FireClient(player, {
        Kind = kind,
        Items = kind == "Items" and Config.Shop.Items or Config.TeamUpgrades.Items,
    })
end

local function connectPrompt(prompt)
    prompt.Triggered:Connect(function(player)
        local shopPart = prompt.Parent
        local ok, reason = ArenaState.CanUseShop(player, shopPart)
        if not ok then
            ArenaState.PushAnnouncement(reason or "Acesso negado a loja", "Warning")
            return
        end

        openShop(player, shopPart:GetAttribute("ShopKind"))
    end)
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
        ArenaState.PushAnnouncement(reason or "Compra recusada", "Warning")
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = reason or "Compra recusada",
        })
        return
    end

    if not ArenaState.CanAfford(player, item.ResourceType, item.Cost) then
        ArenaState.PushAnnouncement(player.Name .. " nao tem saldo para " .. item.DisplayName, "Warning")
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = "Saldo insuficiente",
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
        ArenaState.PushAnnouncement(err or "Falha ao entregar item", "Danger")
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = err or "Falha ao entregar item",
            ItemId = item.Id,
        })
        return
    end

    ArenaState.PushAnnouncement(player.Name .. " comprou " .. item.DisplayName, "Success")
    ArenaState.PushFeedback(player, "PurchaseSuccess", {
        ItemId = item.Id,
        DisplayName = item.DisplayName,
    })
end)

local world = workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    if descendant:IsA("ProximityPrompt") and (descendant.Name == "ItemShopPrompt" or descendant.Name == "UpgradeShopPrompt") then
        connectPrompt(descendant)
    end
end
