local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldData = require(Shared:WaitForChild("WorldData"))

local MissionState = require(script.Parent:WaitForChild("MissionState"))

local connected = {}

local function teleportToFinalRoom(player)
    local character = player.Character
    if not character then
        return
    end

    character:PivotTo(CFrame.new(WorldData.FinalRoomAccess.TargetPosition))
end

local function connectPrompt(prompt)
    if connected[prompt] then
        return
    end

    connected[prompt] = true
    prompt.Triggered:Connect(function(player)
        if MissionState.IsComplete(player) then
            teleportToFinalRoom(player)
            MissionState.SendState(player, Config.Mission.PhotoPromptMessage)
        else
            MissionState.SendState(player, Config.Mission.BlockedFinalRoomMessage)
        end
    end)
end

local world = Workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    if descendant.Name == "FinalGatePrompt" and descendant:IsA("ProximityPrompt") then
        connectPrompt(descendant)
    end
end

world.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "FinalGatePrompt" and descendant:IsA("ProximityPrompt") then
        connectPrompt(descendant)
    end
end)
