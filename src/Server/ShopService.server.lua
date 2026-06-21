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
        if not shopPart or not shopPart:IsA("BasePart") then
            return
        end

        local playerState = ArenaState.GetPlayerState(player)
        if playerState.TeamId ~= shopPart:GetAttribute("TeamId") then
            ArenaState.PushAnnouncement(player.Name .. " tentou abrir uma loja de outro time", "Warning")
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

    if not ArenaState.CanAfford(player, item.ResourceType, item.Cost) then
        ArenaState.PushAnnouncement(player.Name .. " nao tem saldo para " .. item.DisplayName, "Warning")
        return
    end

    if not ArenaState.SpendResource(player, item.ResourceType, item.Cost) then
        return
    end

    local granted, err = ToolFactory.GrantItem(player, item)
    if not granted then
        ArenaState.AddResource(player, item.ResourceType, item.Cost)
        ArenaState.PushAnnouncement(err or "Falha ao entregar item", "Danger")
        return
    end

    ArenaState.PushAnnouncement(player.Name .. " comprou " .. item.DisplayName, "Success")
end)

local world = workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    if descendant:IsA("ProximityPrompt") and (descendant.Name == "ItemShopPrompt" or descendant.Name == "UpgradeShopPrompt") then
        connectPrompt(descendant)
    end
end
