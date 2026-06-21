local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local collectibleCollected = Remotes.GetRemote("CollectibleCollected")
local poiActivated = Remotes.GetRemote("PoiActivated")
local missionStateUpdated = Remotes.GetRemote("MissionStateUpdated")
local finalRoomUnlocked = Remotes.GetRemote("FinalRoomUnlocked")

local theme = Config.UI.Theme

local existingGui = playerGui:FindFirstChild("CSFanZoneHUD")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CSFanZoneHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromOffset(390, 196)
root.Position = UDim2.fromOffset(18, 18)
root.BackgroundColor3 = theme.BackgroundColor
root.BackgroundTransparency = 0.08
root.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = theme.AccentColor
stroke.Thickness = 2
stroke.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 30)
title.Position = UDim2.fromOffset(12, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = Config.UI.Title
title.TextColor3 = theme.TextColor
title.TextSize = 23
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root

local objective = Instance.new("TextLabel")
objective.Name = "Objective"
objective.Size = UDim2.new(1, -24, 0, 42)
objective.Position = UDim2.fromOffset(12, 42)
objective.BackgroundTransparency = 1
objective.Font = Enum.Font.Gotham
objective.Text = Config.Mission.ObjectiveText
objective.TextColor3 = theme.MutedTextColor
objective.TextSize = 16
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top
objective.Parent = root

local memories = Instance.new("TextLabel")
memories.Name = "Memories"
memories.Size = UDim2.new(0.5, -18, 0, 28)
memories.Position = UDim2.fromOffset(12, 92)
memories.BackgroundColor3 = theme.PanelColor
memories.Font = Enum.Font.GothamBold
memories.Text = Config.UI.CollectiblesLabel .. ": 0/" .. tostring(Config.Mission.CollectibleGoal)
memories.TextColor3 = theme.SecondaryAccentColor
memories.TextSize = 18
memories.Parent = root

local memoriesCorner = Instance.new("UICorner")
memoriesCorner.CornerRadius = UDim.new(0, 8)
memoriesCorner.Parent = memories

local pois = Instance.new("TextLabel")
pois.Name = "POIs"
pois.Size = UDim2.new(0.5, -18, 0, 28)
pois.Position = UDim2.new(0.5, 6, 0, 92)
pois.BackgroundColor3 = theme.PanelColor
pois.Font = Enum.Font.GothamBold
pois.Text = Config.UI.PoiLabel .. ": 0/" .. tostring(Config.Mission.PoiGoal)
pois.TextColor3 = theme.AccentColor
pois.TextSize = 18
pois.Parent = root

local poisCorner = Instance.new("UICorner")
poisCorner.CornerRadius = UDim.new(0, 8)
poisCorner.Parent = pois

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Size = UDim2.new(1, -24, 0, 54)
message.Position = UDim2.fromOffset(12, 132)
message.BackgroundTransparency = 1
message.Font = Enum.Font.GothamMedium
message.Text = Config.Mission.StartMessage
message.TextColor3 = theme.TextColor
message.TextSize = 16
message.TextWrapped = true
message.TextXAlignment = Enum.TextXAlignment.Left
message.TextYAlignment = Enum.TextYAlignment.Top
message.Parent = root

local function applyState(payload)
    if typeof(payload) ~= "table" then
        return
    end

    local collectibleCount = payload.CollectiblesFound or 0
    local collectibleGoal = payload.CollectibleGoal or Config.Mission.CollectibleGoal
    local poiCount = payload.POIsActivated or 0
    local poiGoal = payload.POIGoal or Config.Mission.PoiGoal

    memories.Text = string.format("%s: %d/%d", Config.UI.CollectiblesLabel, collectibleCount, collectibleGoal)
    pois.Text = string.format("%s: %d/%d", Config.UI.PoiLabel, poiCount, poiGoal)

    if payload.Objective then
        objective.Text = payload.Objective
    end

    if payload.Message then
        message.Text = payload.Message
    end

    if payload.IsComplete then
        stroke.Color = theme.SuccessColor
        message.TextColor3 = theme.SuccessColor
    end
end

collectibleCollected.OnClientEvent:Connect(function(payload)
    if typeof(payload) == "table" then
        message.Text = payload.Message or "Memoria registrada."
    end
end)

poiActivated.OnClientEvent:Connect(function(payload)
    if typeof(payload) == "table" then
        message.Text = payload.Message or "Ponto ativado."
    end
end)

missionStateUpdated.OnClientEvent:Connect(applyState)
finalRoomUnlocked.OnClientEvent:Connect(applyState)
