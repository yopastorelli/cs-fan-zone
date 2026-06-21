local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local requestTeleport = Remotes.GetRemote("RequestTeleport")
local theme = Config.UI.Theme

local existingGui = playerGui:FindFirstChild("CSFanZoneNavigation")
if existingGui then
    existingGui:Destroy()
end

local navGui = Instance.new("ScreenGui")
navGui.Name = "CSFanZoneNavigation"
navGui.ResetOnSpawn = false
navGui.Parent = playerGui

local navFrame = Instance.new("Frame")
navFrame.Size = UDim2.fromOffset(420, 56)
navFrame.Position = UDim2.new(0.5, -210, 1, -76)
navFrame.BackgroundColor3 = theme.BackgroundColor
navFrame.BackgroundTransparency = 0.15
navFrame.Parent = navGui

local navCorner = Instance.new("UICorner")
navCorner.CornerRadius = UDim.new(0, 14)
navCorner.Parent = navFrame

local navStroke = Instance.new("UIStroke")
navStroke.Color = theme.AccentColor
navStroke.Thickness = 2
navStroke.Parent = navFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.Padding = UDim.new(0, 8)
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.Parent = navFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = navFrame

for _, areaName in ipairs(Config.UI.PortalButtons) do
    local button = Instance.new("TextButton")
    button.Name = areaName .. "Button"
    button.Size = UDim2.fromOffset(92, 36)
    button.BackgroundColor3 = Config.Areas[areaName].AccentColor
    button.Font = Enum.Font.GothamBold
    button.Text = areaName
    button.TextSize = 15
    button.TextColor3 = Color3.fromRGB(18, 18, 18)
    button.Parent = navFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        requestTeleport:FireServer(areaName)
    end)
end

local connectedPrompts = {}

local function connectPrompt(prompt)
    if connectedPrompts[prompt] then
        return
    end

    connectedPrompts[prompt] = true
    prompt.Triggered:Connect(function()
        local targetArea = prompt.Parent and prompt.Parent:GetAttribute("TargetArea")
        if targetArea then
            requestTeleport:FireServer(targetArea)
        end
    end)
end

local function scanPrompts()
    local world = Workspace:FindFirstChild("CSFanZone")
    if not world then
        return
    end

    local portalsFolder = world:FindFirstChild(Config.Areas.Portals.Name)
    if not portalsFolder then
        return
    end

    for _, descendant in ipairs(portalsFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Name == "PortalPrompt" then
            connectPrompt(descendant)
        end
    end
end

scanPrompts()
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "CSFanZone" then
        task.wait(1)
        scanPrompts()
    end
end)
