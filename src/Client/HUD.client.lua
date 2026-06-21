local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui

local function updateScale()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X < 760 then
        uiScale.Scale = 0.78
    elseif viewport.X < 1020 then
        uiScale.Scale = 0.9
    else
        uiScale.Scale = 1
    end
end

updateScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local function makeFrame(parent, name, size, position, anchor, color, transparency)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = anchor or Vector2.new(0, 0)
    frame.BackgroundColor3 = color or theme.BackgroundColor
    frame.BackgroundTransparency = transparency or 0.05
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.AccentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = frame

    return frame, stroke
end

local function makeLabel(parent, name, text, size, position, font, textSize, color, xAlignment)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position or UDim2.fromScale(0, 0)
    label.BackgroundTransparency = 1
    label.Font = font or Enum.Font.Gotham
    label.Text = text or ""
    label.TextColor3 = color or theme.TextColor
    label.TextSize = textSize or 16
    label.TextWrapped = true
    label.TextXAlignment = xAlignment or Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function addPadding(parent, padding)
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0, padding)
    uiPadding.PaddingBottom = UDim.new(0, padding)
    uiPadding.PaddingLeft = UDim.new(0, padding)
    uiPadding.PaddingRight = UDim.new(0, padding)
    uiPadding.Parent = parent
    return uiPadding
end

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

local function getTeamDisplayName(teamId)
    for _, teamConfig in ipairs(Config.Teams) do
        if teamConfig.Id == teamId then
            return teamConfig.DisplayName
        end
    end
    return teamId or "Desconhecido"
end

local topBar = makeFrame(screenGui, "TopBar", UDim2.fromOffset(430, 64), UDim2.new(0.5, 0, 0, 14), Vector2.new(0.5, 0), theme.BackgroundColor, 0.03)
makeLabel(topBar, "Title", Config.UI.Title, UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 8), Enum.Font.GothamBold, 20, theme.TextColor, Enum.TextXAlignment.Center)
local stateLabel = makeLabel(topBar, "State", Config.UI.QueueText, UDim2.new(0.5, -12, 0, 22), UDim2.fromOffset(12, 36), Enum.Font.GothamBold, 15, theme.WarningColor, Enum.TextXAlignment.Left)
local timerLabel = makeLabel(topBar, "Timer", "Tempo: --", UDim2.new(0.5, -12, 0, 22), UDim2.new(0.5, 0, 0, 36), Enum.Font.GothamBold, 15, theme.WarningColor, Enum.TextXAlignment.Right)

local leftPanel = makeFrame(screenGui, "TeamPanel", UDim2.fromOffset(260, 150), UDim2.new(0, 18, 0.5, -75), Vector2.new(0, 0), theme.BackgroundColor, 0.06)
addPadding(leftPanel, 12)
local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 8)
leftLayout.Parent = leftPanel
local teamLabel = makeLabel(leftPanel, "Team", "Time: Sem dupla", UDim2.new(1, 0, 0, 26), nil, Enum.Font.GothamBold, 17, theme.TextColor)
local coreLabel = makeLabel(leftPanel, "Core", "Nucleo: --", UDim2.new(1, 0, 0, 24), nil, Enum.Font.GothamBold, 16, theme.MutedTextColor)
local upgradeLabel = makeLabel(leftPanel, "Upgrades", "Upgrades: --", UDim2.new(1, 0, 0, 44), nil, Enum.Font.Gotham, 14, theme.MutedTextColor)

local standingsPanel = makeFrame(screenGui, "StandingsPanel", UDim2.fromOffset(286, 220), UDim2.new(1, -18, 0.5, -110), Vector2.new(1, 0), theme.BackgroundColor, 0.06)
addPadding(standingsPanel, 10)
makeLabel(standingsPanel, "StandingsTitle", "Duplas", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 0), Enum.Font.GothamBold, 18, theme.TextColor)
local standingsList = Instance.new("Frame")
standingsList.Name = "Rows"
standingsList.Size = UDim2.new(1, 0, 1, -30)
standingsList.Position = UDim2.fromOffset(0, 30)
standingsList.BackgroundTransparency = 1
standingsList.Parent = standingsPanel
local standingsLayout = Instance.new("UIListLayout")
standingsLayout.Padding = UDim.new(0, 5)
standingsLayout.Parent = standingsList

local standingRows = {}
for _ = 1, #Config.Teams do
    local row = makeLabel(standingsList, "StandingRow", "-", UDim2.new(1, 0, 0, 22), nil, Enum.Font.GothamBold, 14, theme.MutedTextColor)
    row.BackgroundColor3 = theme.PanelColor
    row.BackgroundTransparency = 0.32
    standingRows[#standingRows + 1] = row
end

local resourceBar = makeFrame(screenGui, "ResourceBar", UDim2.fromOffset(430, 58), UDim2.new(0.5, 0, 1, -22), Vector2.new(0.5, 1), theme.BackgroundColor, 0.05)
addPadding(resourceBar, 8)
local resourceLayout = Instance.new("UIListLayout")
resourceLayout.FillDirection = Enum.FillDirection.Horizontal
resourceLayout.Padding = UDim.new(0, 8)
resourceLayout.Parent = resourceBar

local resourceLabels = {}
for _, resourceType in ipairs({ "Iron", "Gold", "Emerald" }) do
    local chip = makeFrame(resourceBar, resourceType .. "Chip", UDim2.new(1 / 3, -6, 1, 0), UDim2.fromScale(0, 0), Vector2.new(0, 0), theme.PanelColor, 0.04)
    chip.Parent = resourceBar
    local label = makeLabel(chip, "Label", string.format("%s: 0", Config.UI.ResourceLabels[resourceType]), UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Enum.Font.GothamBlack, 16, theme.TextColor, Enum.TextXAlignment.Center)
    resourceLabels[resourceType] = { Frame = chip, Label = label }
end

local onboardingCard = makeFrame(screenGui, "OnboardingCard", UDim2.fromOffset(470, 242), UDim2.new(0.5, 0, 0.54, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.03)
addPadding(onboardingCard, 16)
makeLabel(onboardingCard, "OnboardingTitle", Config.UI.Onboarding.Title, UDim2.new(1, 0, 0, 32), UDim2.fromOffset(0, 0), Enum.Font.GothamBlack, 25, theme.TextColor, Enum.TextXAlignment.Center)
local queueLabel = makeLabel(onboardingCard, "Queue", "Fila: 0/0 jogadores", UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 38), Enum.Font.GothamBold, 17, theme.WarningColor, Enum.TextXAlignment.Center)
local objectiveRows = {}
for index, objective in ipairs(Config.UI.Onboarding.Objectives) do
    objectiveRows[index] = makeLabel(onboardingCard, "Objective" .. index, string.format("%d. %s", index, objective), UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 70 + ((index - 1) * 34)), Enum.Font.GothamBold, 16, theme.TextColor)
end

local countdownCard = makeFrame(screenGui, "CountdownCard", UDim2.fromOffset(390, 170), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.02)
local countdownTitle = makeLabel(countdownCard, "Title", "Partida iniciando", UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 18), Enum.Font.GothamBlack, 25, theme.TextColor, Enum.TextXAlignment.Center)
local countdownValue = makeLabel(countdownCard, "Value", "20", UDim2.new(1, -24, 0, 62), UDim2.fromOffset(12, 56), Enum.Font.GothamBlack, 48, theme.WarningColor, Enum.TextXAlignment.Center)
makeLabel(countdownCard, "Body", Config.UI.Onboarding.StartingText, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 124), Enum.Font.GothamBold, 16, theme.MutedTextColor, Enum.TextXAlignment.Center)
countdownCard.Visible = false

local resultBanner = makeFrame(screenGui, "ResultBanner", UDim2.fromOffset(560, 94), UDim2.new(0.5, 0, 0.22, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.02)
local resultText = makeLabel(resultBanner, "ResultText", "", UDim2.new(1, -24, 1, -20), UDim2.fromOffset(12, 10), Enum.Font.GothamBlack, 26, theme.TextColor, Enum.TextXAlignment.Center)
resultBanner.Visible = false

local announcement = makeLabel(screenGui, "Announcement", "", UDim2.fromOffset(520, 44), UDim2.new(0.5, 0, 1, -92), Enum.Font.GothamBlack, 18, theme.TextColor, Enum.TextXAlignment.Center)
announcement.AnchorPoint = Vector2.new(0.5, 1)
announcement.BackgroundColor3 = theme.PanelColor
announcement.BackgroundTransparency = 0.08
announcement.Visible = false
local announcementCorner = Instance.new("UICorner")
announcementCorner.CornerRadius = UDim.new(0, 8)
announcementCorner.Parent = announcement

local shopFrame, shopStroke = makeFrame(screenGui, "ShopFrame", UDim2.fromOffset(540, 390), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.02)
shopFrame.Visible = false
addPadding(shopFrame, 14)
makeLabel(shopFrame, "ShopTitle", "Loja", UDim2.new(1, -60, 0, 32), UDim2.fromOffset(0, 0), Enum.Font.GothamBlack, 24, theme.TextColor)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(38, 32)
closeButton.Position = UDim2.new(1, -38, 0, 0)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBlack
closeButton.TextSize = 18
closeButton.TextColor3 = theme.TextColor
closeButton.BackgroundColor3 = theme.DangerColor
closeButton.Parent = shopFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local categoryBar = Instance.new("Frame")
categoryBar.Name = "CategoryBar"
categoryBar.Size = UDim2.new(1, 0, 0, 40)
categoryBar.Position = UDim2.fromOffset(0, 42)
categoryBar.BackgroundTransparency = 1
categoryBar.Parent = shopFrame
local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 6)
categoryLayout.Parent = categoryBar

local itemHolder = Instance.new("Frame")
itemHolder.Name = "Items"
itemHolder.Size = UDim2.new(1, 0, 1, -96)
itemHolder.Position = UDim2.fromOffset(0, 92)
itemHolder.BackgroundTransparency = 1
itemHolder.Parent = shopFrame
local itemGrid = Instance.new("UIGridLayout")
itemGrid.CellPadding = UDim2.fromOffset(8, 8)
itemGrid.CellSize = UDim2.fromOffset(250, 72)
itemGrid.Parent = itemHolder

local currentShopKind = "Items"
local currentItems = {}
local currentCategory = "Todos"
local currentPhase = "Lobby"
local currentMatchState = "Waiting"
local currentResources = { Iron = 0, Gold = 0, Emerald = 0 }
local currentUpgrades = { sharpness = 0, protection = 0, forge = 1 }

local function playConfiguredSound(soundId)
    if not soundId or soundId == "rbxassetid://0" then
        return
    end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.55
    sound.Parent = screenGui
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local function pulse(frame, color)
    local original = frame.BackgroundColor3
    TweenService:Create(frame, TweenInfo.new(0.08), { BackgroundColor3 = color }):Play()
    task.delay(0.14, function()
        if frame.Parent then
            TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundColor3 = original }):Play()
        end
    end)
end

local function showAnnouncement(message, color, duration)
    announcement.Text = message or ""
    announcement.TextColor3 = color or theme.TextColor
    announcement.Visible = announcement.Text ~= ""
    task.delay(duration or 3, function()
        announcement.Visible = false
    end)
end

local function updatePhaseVisibility()
    local showLobby = currentPhase == "Lobby"
    local showCountdown = showLobby and currentMatchState == "Starting"
    local showCompetitive = currentPhase == "InMatch" or currentPhase == "Spectating"

    onboardingCard.Visible = showLobby and not showCountdown
    countdownCard.Visible = showCountdown
    leftPanel.Visible = showCompetitive
    standingsPanel.Visible = showCompetitive
    resourceBar.Visible = showCompetitive and currentPhase == "InMatch"
end

local function clearChildrenOfClass(parent, className)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA(className) then
            child:Destroy()
        end
    end
end

local function getCategories()
    if currentShopKind == "Upgrades" then
        return { "Upgrades" }
    end
    local seen = { Todos = true }
    local categories = { "Todos" }
    for _, item in ipairs(currentItems) do
        if item.Category and not seen[item.Category] then
            seen[item.Category] = true
            categories[#categories + 1] = item.Category
        end
    end
    return categories
end

local function canAfford(resourceType, cost)
    return (currentResources[resourceType] or 0) >= (cost or 0)
end

local function getUpgradeCost(item)
    local nextLevel = (currentUpgrades[item.Id] or 0) + 1
    return item.TierCosts[nextLevel], nextLevel
end

local function buildShopButtons()
    clearChildrenOfClass(categoryBar, "TextButton")
    clearChildrenOfClass(itemHolder, "TextButton")

    for _, category in ipairs(getCategories()) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.fromOffset(96, 36)
        button.Text = category
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.TextColor3 = theme.TextColor
        button.BackgroundColor3 = category == currentCategory and theme.AccentColor or theme.PanelColor
        button.Parent = categoryBar
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        button.MouseButton1Click:Connect(function()
            currentCategory = category
            buildShopButtons()
        end)
    end

    for _, item in ipairs(currentItems) do
        if currentShopKind == "Upgrades" or currentCategory == "Todos" or item.Category == currentCategory then
            local cost = item.Cost
            local maxed = false
            if currentShopKind == "Upgrades" then
                cost = getUpgradeCost(item)
                maxed = cost == nil
            end
            local affordable = not maxed and canAfford(item.ResourceType, cost)

            local button = Instance.new("TextButton")
            button.TextWrapped = true
            button.Font = Enum.Font.GothamBold
            button.TextSize = 14
            button.TextColor3 = theme.TextColor
            button.BackgroundColor3 = affordable and theme.AccentColor or theme.PanelColor
            button.AutoButtonColor = affordable
            button.Text = maxed and (item.DisplayName .. "\nMAX") or string.format("%s\n%s %d", item.DisplayName, Config.UI.ResourceLabels[item.ResourceType] or item.ResourceType, cost or 0)
            button.Parent = itemHolder
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button

            button.MouseButton1Click:Connect(function()
                if maxed or not affordable then
                    pulse(button, theme.DangerColor)
                    playConfiguredSound(Config.Audio.ErrorSoundId)
                    return
                end
                if currentShopKind == "Items" then
                    remotes.PurchaseRequested:FireServer({ ItemId = item.Id })
                else
                    remotes.UpgradeRequested:FireServer({ UpgradeId = item.Id })
                end
            end)
        end
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
    currentCategory = currentShopKind == "Upgrades" and "Upgrades" or "Todos"
    local title = shopFrame:FindFirstChild("ShopTitle")
    if title and title:IsA("TextLabel") then
        title.Text = currentShopKind == "Items" and "Loja de Itens" or "Upgrades da Dupla"
    end
    buildShopButtons()
    shopFrame.Visible = true
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" or typeof(payload.Resources) ~= "table" then
        return
    end

    for resourceType, labelData in pairs(resourceLabels) do
        currentResources[resourceType] = payload.Resources[resourceType] or 0
        labelData.Label.Text = string.format("%s: %d", Config.UI.ResourceLabels[resourceType], currentResources[resourceType])
    end
    if shopFrame.Visible then
        buildShopButtons()
    end
end)

remotes.TeamStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    currentPhase = payload.PlayerPhase or currentPhase
    currentUpgrades = payload.OwnUpgrades or currentUpgrades

    teamLabel.Text = "Time: " .. getTeamDisplayName(payload.OwnTeamId)
    coreLabel.Text = string.format("Nucleo: %s (%d)", payload.OwnCoreAlive and "Ativo" or "Destruido", payload.OwnCoreHealth or 0)
    coreLabel.TextColor3 = payload.OwnCoreAlive and theme.SuccessColor or theme.DangerColor
    upgradeLabel.Text = string.format("Upgrades: espada %d | defesa %d | forja %d", currentUpgrades.sharpness or 0, currentUpgrades.protection or 0, currentUpgrades.forge or 1)

    local standings = payload.Standings or {}
    for index, row in ipairs(standingRows) do
        local standing = standings[index]
        if standing then
            row.Text = string.format("  %s | vivos %d | nucleo %s", standing.BiomeDisplayName, standing.AlivePlayers, standing.CoreAlive and "ON" or "OFF")
            row.TextColor3 = standing.Color or theme.TextColor
            row.BackgroundTransparency = standing.CoreAlive and 0.22 or 0.5
        else
            row.Text = "-"
            row.TextColor3 = theme.MutedTextColor
        end
    end

    updatePhaseVisibility()
end)

remotes.MatchStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    currentPhase = payload.PlayerPhase or currentPhase
    currentMatchState = payload.MatchState or currentMatchState

    stateLabel.Text = Config.UI.MatchStateLabels[currentMatchState] or currentMatchState
    local objectives = payload.ObjectiveText or Config.UI.Onboarding.Objectives
    for index, row in ipairs(objectiveRows) do
        row.Text = string.format("%d. %s", index, objectives[index] or "")
    end
    queueLabel.Text = string.format("Fila: %d/%d jogadores", payload.QueueCount or 0, payload.MinPlayersToStart or Config.Match.MinPlayersToStart)

    local remaining = math.max(0, (payload.StateEndsAt or 0) - os.time())
    timerLabel.Text = string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
    countdownValue.Text = tostring(remaining)

    if currentMatchState == "Ended" then
        resultBanner.Visible = true
        if payload.EndReason == "Victory" and payload.WinningTeamId then
            resultText.Text = string.format("%s %s\n%s", Config.UI.Results.VictoryPrefix, getTeamDisplayName(payload.WinningTeamId), Config.UI.Results.ReturnText)
            resultText.TextColor3 = theme.SuccessColor
            playConfiguredSound(Config.Audio.VictorySoundId)
        elseif payload.EndReason == "Draw" then
            resultText.Text = Config.UI.Results.DrawText .. "\n" .. Config.UI.Results.ReturnText
            resultText.TextColor3 = theme.WarningColor
        end
    else
        resultBanner.Visible = false
    end

    updatePhaseVisibility()
end)

remotes.RespawnStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    if payload.Spectating then
        currentPhase = "Spectating"
        showAnnouncement("Eliminado. Agora voce esta em espectador.", theme.DangerColor, 4)
    else
        showAnnouncement(string.format("Respawn em %ds", payload.RespawnIn or 0), theme.WarningColor, 3)
    end
    updatePhaseVisibility()
end)

remotes.AnnouncementPushed.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end
    showAnnouncement(payload.Message or "", getThemeColor(payload.ColorName), 4)
end)

remotes.FeedbackPushed.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    if payload.Type == "ResourceCollected" and payload.ResourceType and resourceLabels[payload.ResourceType] then
        pulse(resourceLabels[payload.ResourceType].Frame, theme.SuccessColor)
        playConfiguredSound(Config.Audio.PickupSoundId)
    elseif payload.Type == "PurchaseSuccess" then
        pulse(shopFrame, theme.SuccessColor)
        playConfiguredSound(Config.Audio.PurchaseSoundId)
    elseif payload.Type == "PurchaseDenied" then
        pulse(shopFrame, theme.DangerColor)
        playConfiguredSound(Config.Audio.ErrorSoundId)
        showAnnouncement(payload.Message or "Acao recusada", theme.DangerColor, 2.5)
    elseif payload.Type == "UpgradeApplied" then
        pulse(leftPanel, theme.SuccessColor)
        playConfiguredSound(Config.Audio.UpgradeSoundId)
    elseif payload.Type == "CoreHit" then
        showAnnouncement("Nucleo sob ataque", theme.WarningColor, 2.5)
        playConfiguredSound(Config.Audio.CoreHitSoundId)
    elseif payload.Type == "CoreDestroyed" then
        showAnnouncement("Nucleo destruido", theme.DangerColor, 4)
        playConfiguredSound(Config.Audio.CoreBreakSoundId)
    end
end)

updatePhaseVisibility()
