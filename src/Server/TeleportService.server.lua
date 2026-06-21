local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local requestTeleport = Remotes.GetRemote("RequestTeleport")

local TELEPORT_COOLDOWN = 0.75

local function getAreaSpawn(targetArea)
    local world = Workspace:FindFirstChild("CSFanZone")
    if not world then
        return nil
    end

    local area = world:FindFirstChild(targetArea)
    if not area then
        return nil
    end

    return area:FindFirstChild("Spawn")
end

local function isAllowedTarget(targetArea)
    return Config.PortalTargets[targetArea] ~= nil
end

local function teleportPlayer(player, targetArea)
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end

    local spawnPart = getAreaSpawn(targetArea)
    if not spawnPart then
        return
    end

    character:PivotTo(spawnPart.CFrame + Vector3.new(0, 4, 0))
end

requestTeleport.OnServerEvent:Connect(function(player, targetArea)
    if typeof(targetArea) ~= "string" or not isAllowedTarget(targetArea) then
        return
    end

    local lastTeleportAt = player:GetAttribute("LastTeleportAt") or 0
    local now = os.clock()
    if now - lastTeleportAt < TELEPORT_COOLDOWN then
        return
    end

    player:SetAttribute("LastTeleportAt", now)
    teleportPlayer(player, Config.PortalTargets[targetArea])
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("LastTeleportAt", 0)
end)
