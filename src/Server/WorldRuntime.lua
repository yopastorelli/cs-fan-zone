local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local remotes = Remotes.GetAll()

local WorldRuntime = {}

local connectedPrompts = {}
local connectedMiddleTriggers = {}
local touchedDebounce = {}

local function openShop(player, kind)
    ArenaState.MarkShopOpened(player)
    remotes.ShopOpened:FireClient(player, {
        Kind = kind,
        Items = kind == "Items" and Config.Shop.Items or Config.TeamUpgrades.Items,
    })
end

function WorldRuntime.RegisterPrompt(prompt)
    if not prompt or connectedPrompts[prompt] then
        return
    end
    connectedPrompts[prompt] = true
    prompt.Triggered:Connect(function(player)
        local shopPart = prompt.Parent
        local ok, reason = ArenaState.CanUseShop(player, shopPart)
        if not ok then
            ArenaState.PushFeedback(player, "PurchaseDenied", {
                Message = reason or Config.UI.Messages.ShopAccessDenied,
            })
            return
        end

        openShop(player, shopPart:GetAttribute("ShopKind"))
    end)
end

function WorldRuntime.RegisterMiddleTrigger(triggerPart)
    if not triggerPart or connectedMiddleTriggers[triggerPart] then
        return
    end
    connectedMiddleTriggers[triggerPart] = true
    triggerPart.Touched:Connect(function(hit)
        local character = hit and hit.Parent
        local player = character and Players:GetPlayerFromCharacter(character)
        if not player or not ArenaState.IsPlayerInMatch(player) then
            return
        end

        local key = tostring(player.UserId) .. ":" .. triggerPart:GetDebugId()
        if touchedDebounce[key] then
            return
        end
        touchedDebounce[key] = true
        ArenaState.MarkReachedMiddleIsland(player)
        task.delay(1.5, function()
            touchedDebounce[key] = nil
        end)
    end)
end

return WorldRuntime
