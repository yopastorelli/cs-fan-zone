local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local remotes = Remotes.GetAll()
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
root.Size = UDim2.fromOffset(420, 320)
root.Position = UDim2.fromOffset(18, 18)
root.BackgroundColor3 = theme.BackgroundColor
root.BackgroundTransparency = 0.06
root.Parent = screenGui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 10)
rootCorner.Parent = root

local rootStroke = Instance.new("UIStroke")
rootStroke.Color = theme.AccentColor
rootStroke.Thickness = 2
rootStroke.Parent = root

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 30)
title.Position = UDim2.fromOffset(12, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = Config.UI.Title
title.TextColor3 = theme.TextColor
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(0.52, -12, 0, 24)
stateLabel.Position = UDim2.fromOffset(12, 46)
stateLabel.BackgroundTransparency = 1
stateLabel.Font = Enum.Font.GothamBold
stateLabel.Text = "Estado: " .. Config.UI.QueueText
stateLabel.TextColor3 = theme.WarningColor
stateLabel.TextSize = 15
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.Parent = root

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0.48, -12, 0, 24)
timerLabel.Position = UDim2.new(0.52, 0, 0, 46)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = "Tempo: --"
timerLabel.TextColor3 = theme.SecondaryAccentColor or theme.WarningColor
timerLabel.TextSize = 15
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Parent = root

local teamLabel = Instance.new("TextLabel")
teamLabel.Size = UDim2.new(1, -24, 0, 24)
teamLabel.Position = UDim2.fromOffset(12, 74)
teamLabel.BackgroundTransparency = 1
teamLabel.Font = Enum.Font.Gotham
teamLabel.Text = "Time: Sem dupla"
teamLabel.TextColor3 = theme.MutedTextColor
teamLabel.TextSize = 15
teamLabel.TextXAlignment = Enum.TextXAlignment.Left
teamLabel.Parent = root

local coreLabel = Instance.new("TextLabel")
coreLabel.Size = UDim2.new(1, -24, 0, 24)
coreLabel.Position = UDim2.fromOffset(12, 98)
coreLabel.BackgroundTransparency = 1
coreLabel.Font = Enum.Font.Gotham
coreLabel.Text = "Nucleo: --"
coreLabel.TextColor3 = theme.MutedTextColor
coreLabel.TextSize = 15
coreLabel.TextXAlignment = Enum.TextXAlignment.Left
coreLabel.Parent = root

local resourceFrame = Instance.new("Frame")
resourceFrame.Size = UDim2.new(1, -24, 0, 34)
resourceFrame.Position = UDim2.fromOffset(12, 128)
resourceFrame.BackgroundColor3 = theme.PanelColor
resourceFrame.Parent = root

local resourceCorner = Instance.new("UICorner")
resourceCorner.CornerRadius = UDim.new(0, 8)
resourceCorner.Parent = resourceFrame

local resourceLabels = {}
for index, resourceType in ipairs({ "Iron", "Gold", "Emerald" }) do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1 / 3, -8, 1, 0)
    label.Position = UDim2.new((index - 1) / 3, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = string.format("%s: 0", Config.UI.ResourceLabels[resourceType])
    label.TextColor3 = theme.TextColor
    label.TextSize = 16
    label.Parent = resourceFrame
    resourceLabels[resourceType] = label
end

local standingsTitle = Instance.new("TextLabel")
standingsTitle.Size = UDim2.new(1, -24, 0, 24)
standingsTitle.Position = UDim2.fromOffset(12, 172)
standingsTitle.BackgroundTransparency = 1
standingsTitle.Font = Enum.Font.GothamBold
standingsTitle.Text = "Duplas"
standingsTitle.TextColor3 = theme.TextColor
standingsTitle.TextSize = 16
standingsTitle.TextXAlignment = Enum.TextXAlignment.Left
standingsTitle.Parent = root

local standingsFrame = Instance.new("Frame")
standingsFrame.Size = UDim2.new(1, -24, 0, 108)
standingsFrame.Position = UDim2.fromOffset(12, 198)
standingsFrame.BackgroundColor3 = theme.PanelColor
standingsFrame.Parent = root

local standingsCorner = Instance.new("UICorner")
standingsCorner.CornerRadius = UDim.new(0, 8)
standingsCorner.Parent = standingsFrame

local standingsLayout = Instance.new("UIListLayout")
standingsLayout.Padding = UDim.new(0, 4)
standingsLayout.Parent = standingsFrame

local standingRows = {}
for _ = 1, #Config.Teams do
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -12, 0, 14)
    row.BackgroundTransparency = 1
    row.Font = Enum.Font.Gotham
    row.Text = "-"
    row.TextColor3 = theme.MutedTextColor
    row.TextSize = 14
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Parent = standingsFrame
    standingRows[#standingRows + 1] = row
end

local announcement = Instance.new("TextLabel")
announcement.Size = UDim2.new(0, 420, 0, 40)
announcement.Position = UDim2.new(0.5, -210, 1, -58)
announcement.BackgroundColor3 = theme.PanelColor
announcement.BackgroundTransparency = 0.08
announcement.Font = Enum.Font.GothamBold
announcement.Text = ""
announcement.TextColor3 = theme.TextColor
announcement.TextScaled = true
announcement.Visible = false
announcement.Parent = screenGui

local announcementCorner = Instance.new("UICorner")
announcementCorner.CornerRadius = UDim.new(0, 8)
announcementCorner.Parent = announcement

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.fromOffset(430, 330)
shopFrame.Position = UDim2.new(0.5, -215, 0.5, -165)
shopFrame.BackgroundColor3 = theme.BackgroundColor
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopFrame

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = theme.AccentColor
shopStroke.Thickness = 2
shopStroke.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -60, 0, 28)
shopTitle.Position = UDim2.fromOffset(14, 10)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "Loja"
shopTitle.TextColor3 = theme.TextColor
shopTitle.TextSize = 22
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shopFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(34, 28)
closeButton.Position = UDim2.new(1, -46, 0, 10)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = theme.TextColor
closeButton.BackgroundColor3 = theme.DangerColor
closeButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Padding = UDim.new(0, 6)

local buttonHolder = Instance.new("Frame")
buttonHolder.Size = UDim2.new(1, -24, 1, -56)
buttonHolder.Position = UDim2.fromOffset(12, 46)
buttonHolder.BackgroundTransparency = 1
buttonHolder.Parent = shopFrame
buttonLayout.Parent = buttonHolder

local currentShopKind = "Items"
local currentItems = {}

local function getThemeColor(name)
    if name == "Success" then
        return theme.SuccessColor
    elseif name == "Warning" then
        return theme.WarningColor
    elseif name == "Danger" then
        return theme.DangerColor
    end
    return theme.AccentColor
end

local function clearShopButtons()
    for _, child in ipairs(buttonHolder:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function fireShopRequest(item)
    if currentShopKind == "Items" then
        remotes.PurchaseRequested:FireServer({ ItemId = item.Id })
    else
        remotes.UpgradeRequested:FireServer({ UpgradeId = item.Id })
    end
end

local function buildShopButtons()
    clearShopButtons()

    for _, item in ipairs(currentItems) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 42)
        button.BackgroundColor3 = theme.PanelColor
        button.TextColor3 = theme.TextColor
        button.Font = Enum.Font.GothamBold
        button.TextSize = 15

        if currentShopKind == "Items" then
            button.Text = string.format("%s | %s %d", item.DisplayName, item.ResourceType, item.Cost)
        else
            local costs = {}
            for _, cost in ipairs(item.TierCosts) do
                costs[#costs + 1] = tostring(cost)
            end
            button.Text = string.format("%s | %s %s", item.DisplayName, item.ResourceType, table.concat(costs, "/"))
        end

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            fireShopRequest(item)
        end)

        button.Parent = buttonHolder
    end
end

closeButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

remotes.ShopOpened.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    currentShopKind = payload.Kind or "Items"
    currentItems = payload.Items or {}
    shopTitle.Text = currentShopKind == "Items" and "Loja" or "Upgrades"
    buildShopButtons()
    shopFrame.Visible = true
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" or typeof(payload.Resources) ~= "table" then
        return
    end

    for resourceType, label in pairs(resourceLabels) do
        label.Text = string.format("%s: %d", Config.UI.ResourceLabels[resourceType], payload.Resources[resourceType] or 0)
    end
end)

remotes.TeamStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    local ownTeamName = "Sem dupla"
    if payload.OwnTeamId then
        for _, teamConfig in ipairs(Config.Teams) do
            if teamConfig.Id == payload.OwnTeamId then
                ownTeamName = teamConfig.DisplayName
                break
            end
        end
    end

    teamLabel.Text = "Time: " .. ownTeamName
    coreLabel.Text = string.format("Nucleo: %s (%d)", payload.OwnCoreAlive and "Ativo" or "Destruido", payload.OwnCoreHealth or 0)
    coreLabel.TextColor3 = payload.OwnCoreAlive and theme.SuccessColor or theme.DangerColor

    local standings = payload.Standings or {}
    for index, row in ipairs(standingRows) do
        local standing = standings[index]
        if standing then
            row.Text = string.format("%s | vivos %d | nucleo %s", standing.BiomeDisplayName, standing.AlivePlayers, standing.CoreAlive and "sim" or "nao")
            row.TextColor3 = standing.Color or theme.TextColor
        else
            row.Text = "-"
            row.TextColor3 = theme.MutedTextColor
        end
    end
end)

remotes.MatchStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    local state = payload.MatchState or "Waiting"
    local stateLabelText = Config.UI.MatchStateLabels[state] or state
    stateLabel.Text = "Estado: " .. stateLabelText

    local endsAt = payload.StateEndsAt or 0
    local remaining = math.max(0, endsAt - os.time())
    timerLabel.Text = string.format("Tempo: %02d:%02d", math.floor(remaining / 60), remaining % 60)
end)

remotes.RespawnStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    if payload.Spectating then
        announcement.Text = "Voce foi eliminado e agora esta em espectador."
        announcement.TextColor3 = theme.DangerColor
    else
        announcement.Text = string.format("Respawn em %ds", payload.RespawnIn or 0)
        announcement.TextColor3 = theme.WarningColor
    end
    announcement.Visible = true
    task.delay(3, function()
        announcement.Visible = false
    end)
end)

remotes.AnnouncementPushed.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    announcement.Text = payload.Message or ""
    announcement.TextColor3 = getThemeColor(payload.ColorName)
    announcement.Visible = announcement.Text ~= ""
    task.delay(4, function()
        announcement.Visible = false
    end)
end)
