local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local remotes = Remotes.GetAll()

local function getUpgradeById(upgradeId)
    for _, item in ipairs(Config.TeamUpgrades.Items) do
        if item.Id == upgradeId then
            return item
        end
    end
    return nil
end

remotes.UpgradeRequested.OnServerEvent:Connect(function(player, payload)
    if typeof(payload) ~= "table" or typeof(payload.UpgradeId) ~= "string" then
        return
    end

    local playerState = ArenaState.GetPlayerState(player)
    if not playerState.TeamId or not ArenaState.IsPlayerInMatch(player) then
        return
    end

    local shopPart = ArenaState.GetShopPart(player, "Upgrades")
    local ok, reason = ArenaState.CanUseShop(player, shopPart)
    if not ok then
        ArenaState.PushAnnouncement(reason or "Upgrade recusado", "Warning")
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = reason or "Upgrade recusado",
        })
        return
    end

    local upgrade = getUpgradeById(payload.UpgradeId)
    if not upgrade then
        return
    end

    local currentLevel = ArenaState.GetUpgradeLevel(playerState.TeamId, upgrade.Id)
    local nextLevel = currentLevel + 1
    local cost = upgrade.TierCosts[nextLevel]
    if not cost then
        ArenaState.PushAnnouncement(upgrade.DisplayName .. " ja esta no maximo", "Warning")
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = "Upgrade no maximo",
            UpgradeId = upgrade.Id,
        })
        return
    end

    if not ArenaState.SpendResource(player, upgrade.ResourceType, cost) then
        ArenaState.PushAnnouncement(player.Name .. " nao tem recurso para " .. upgrade.DisplayName, "Warning")
        ArenaState.PushFeedback(player, "PurchaseDenied", {
            Message = "Recurso insuficiente",
            UpgradeId = upgrade.Id,
        })
        return
    end

    ArenaState.AdvanceUpgrade(playerState.TeamId, upgrade.Id)
    ArenaState.PushAnnouncement(player.Name .. " melhorou " .. upgrade.DisplayName, "Success")
    ArenaState.PushFeedback(player, "UpgradeApplied", {
        UpgradeId = upgrade.Id,
        DisplayName = upgrade.DisplayName,
    })
end)
