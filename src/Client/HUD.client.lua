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

local onboardingDismissed = false
local seenFeedbackHints = {}
local baseGuideShownForTeam = {}
local activeHighlights = {}
local missionCard
local missionStepLabel
local missionTitleLabel
local missionHintLabel
local missionTargetLabel
local announcementToken = 0
local currentActiveTeamCount = 0
local clearBaseHighlights
local activeAnnouncementPriority = 0
local activeAnnouncementExpiresAt = 0
local respawnCountdownEndsAt = 0

local announcementPriorities = {
    info = 1,
    warning = 2,
    danger = 3,
}

local function updateScale()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X < 760 then
        uiScale.Scale = 0.84
    elseif viewport.X < 1020 then
        uiScale.Scale = 0.94
    else
        uiScale.Scale = 1
    end
end

player.CharacterAdded:Connect(function()
    table.clear(baseGuideShownForTeam)
    clearBaseHighlights()
    respawnCountdownEndsAt = 0
end)

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

local topBar = makeFrame(screenGui, "TopBar", UDim2.fromOffset(520, 76), UDim2.new(0.5, 0, 0, 16), Vector2.new(0.5, 0), theme.BackgroundColor, 0.01)
local topAccent = Instance.new("Frame")
topAccent.Name = "TopAccent"
topAccent.Size = UDim2.new(1, -20, 0, 3)
topAccent.Position = UDim2.fromOffset(10, 10)
topAccent.BackgroundColor3 = theme.AccentColor
topAccent.BorderSizePixel = 0
topAccent.Parent = topBar
makeLabel(topBar, "Title", Config.UI.Title, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 12), Enum.Font.GothamBlack, 24, theme.TextColor, Enum.TextXAlignment.Center)
local stateLabel = makeLabel(topBar, "State", Config.UI.QueueText, UDim2.new(0.5, -12, 0, 24), UDim2.fromOffset(12, 44), Enum.Font.GothamBold, 17, theme.WarningColor, Enum.TextXAlignment.Left)
local timerLabel = makeLabel(topBar, "Timer", "Tempo: --", UDim2.new(0.5, -12, 0, 24), UDim2.new(0.5, 0, 0, 44), Enum.Font.GothamBold, 17, theme.WarningColor, Enum.TextXAlignment.Right)
local helpRibbon = makeFrame(screenGui, "HelpRibbon", UDim2.fromOffset(560, 38), UDim2.new(0.5, 0, 0, 98), Vector2.new(0.5, 0), theme.BackgroundColor, 0.02)
local helpRibbonText = makeLabel(helpRibbon, "Text", "", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), Enum.Font.GothamBold, 15, theme.MutedTextColor, Enum.TextXAlignment.Center)

local leftPanel = makeFrame(screenGui, "TeamPanel", UDim2.fromOffset(320, 232), UDim2.new(0, 18, 0.5, -116), Vector2.new(0, 0), theme.BackgroundColor, 0.04)
addPadding(leftPanel, 12)
local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 8)
leftLayout.Parent = leftPanel
local teamLabel = makeLabel(leftPanel, "Team", "Time: Sem time", UDim2.new(1, 0, 0, 26), nil, Enum.Font.GothamBold, 17, theme.TextColor)
local coreLabel = makeLabel(leftPanel, "Core", "Totem: --", UDim2.new(1, 0, 0, 24), nil, Enum.Font.GothamBold, 16, theme.MutedTextColor)
local upgradeLabel = makeLabel(leftPanel, "RespawnState", "Respawn: --", UDim2.new(1, 0, 0, 44), nil, Enum.Font.Gotham, 14, theme.MutedTextColor)
local formatLabel = makeLabel(leftPanel, "Format", "Formato: --", UDim2.new(1, 0, 0, 22), nil, Enum.Font.GothamBold, 14, theme.WarningColor)
local loadoutHint1 = makeLabel(leftPanel, "Hint1", "", UDim2.new(1, 0, 0, 22), nil, Enum.Font.GothamBold, 13, theme.TextColor)
local loadoutHint2 = makeLabel(leftPanel, "Hint2", "", UDim2.new(1, 0, 0, 22), nil, Enum.Font.GothamBold, 13, theme.TextColor)
local loadoutHint3 = makeLabel(leftPanel, "Hint3", "", UDim2.new(1, 0, 0, 22), nil, Enum.Font.GothamBold, 13, theme.TextColor)

local standingsPanel = makeFrame(screenGui, "StandingsPanel", UDim2.fromOffset(310, 252), UDim2.new(1, -18, 0.5, -126), Vector2.new(1, 0), theme.BackgroundColor, 0.04)
addPadding(standingsPanel, 10)
local standingsTitle = makeLabel(standingsPanel, "StandingsTitle", "Times", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 0), Enum.Font.GothamBold, 18, theme.TextColor)
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
    local row = makeLabel(standingsList, "StandingRow", "-", UDim2.new(1, 0, 0, 28), nil, Enum.Font.GothamBold, 15, theme.MutedTextColor)
    row.BackgroundColor3 = theme.PanelColor
    row.BackgroundTransparency = 0.32
    standingRows[#standingRows + 1] = row
end

local resourceBar = makeFrame(screenGui, "ResourceBar", UDim2.fromOffset(470, 64), UDim2.new(0.5, 0, 1, -22), Vector2.new(0.5, 1), theme.BackgroundColor, 0.03)
addPadding(resourceBar, 8)
local resourceLayout = Instance.new("UIListLayout")
resourceLayout.FillDirection = Enum.FillDirection.Horizontal
resourceLayout.Padding = UDim.new(0, 8)
resourceLayout.Parent = resourceBar

local resourceLabels = {}
for _, resourceType in ipairs({ "Iron", "Gold", "Emerald" }) do
    local chip = makeFrame(resourceBar, resourceType .. "Chip", UDim2.new(1 / 3, -6, 1, 0), UDim2.fromScale(0, 0), Vector2.new(0, 0), theme.PanelColor, 0.04)
    chip.Parent = resourceBar
    local label = makeLabel(chip, "Label", string.format("%s: 0", Config.UI.ResourceLabels[resourceType]), UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Enum.Font.GothamBlack, 17, theme.TextColor, Enum.TextXAlignment.Center)
    resourceLabels[resourceType] = { Frame = chip, Label = label }
end

local onboardingCard = makeFrame(screenGui, "OnboardingCard", UDim2.fromOffset(400, 208), UDim2.new(0, 18, 0, 92), Vector2.new(0, 0), theme.BackgroundColor, 0.02)
addPadding(onboardingCard, 16)
makeLabel(onboardingCard, "OnboardingTitle", Config.UI.Onboarding.Title, UDim2.new(1, -94, 0, 28), UDim2.fromOffset(0, 0), Enum.Font.GothamBlack, 22, theme.TextColor, Enum.TextXAlignment.Left)
local onboardingSubtitle = makeLabel(onboardingCard, "OnboardingSubtitle", "Leia a rota, o formato da rodada e seu proximo passo.", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 28), Enum.Font.GothamBold, 13, theme.MutedTextColor, Enum.TextXAlignment.Left)

local onboardingClose = Instance.new("TextButton")
onboardingClose.Name = "OnboardingClose"
onboardingClose.Size = UDim2.fromOffset(82, 28)
onboardingClose.Position = UDim2.new(1, -82, 0, 0)
onboardingClose.Text = "Fechar"
onboardingClose.Font = Enum.Font.GothamBold
onboardingClose.TextSize = 14
onboardingClose.TextColor3 = theme.TextColor
onboardingClose.BackgroundColor3 = theme.PanelColor
onboardingClose.Parent = onboardingCard
local onboardingCloseCorner = Instance.new("UICorner")
onboardingCloseCorner.CornerRadius = UDim.new(0, 8)
onboardingCloseCorner.Parent = onboardingClose

local queueLabel = makeLabel(onboardingCard, "Queue", string.format("Fila: 0/%d jogadores", Config.Match.MinPlayersToStart), UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 62), Enum.Font.GothamBold, 16, theme.WarningColor, Enum.TextXAlignment.Left)
local formatQueueLabel = makeLabel(onboardingCard, "FormatQueue", "Formato previsto: --", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 84), Enum.Font.GothamBold, 15, theme.MutedTextColor, Enum.TextXAlignment.Left)
local objectiveRows = {}
for index, objective in ipairs(Config.UI.Onboarding.Objectives) do
    objectiveRows[index] = makeLabel(onboardingCard, "Objective" .. index, string.format("%d. %s", index, objective), UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 114 + ((index - 1) * 20)), Enum.Font.GothamBold, 12, theme.TextColor)
end

local helpToggle = Instance.new("TextButton")
helpToggle.Name = "HelpToggle"
helpToggle.Size = UDim2.fromOffset(86, 34)
helpToggle.Position = UDim2.new(0, 18, 0, 52)
helpToggle.Text = "Ajuda"
helpToggle.Font = Enum.Font.GothamBold
helpToggle.TextSize = 15
helpToggle.TextColor3 = theme.TextColor
helpToggle.BackgroundColor3 = theme.PanelColor
helpToggle.Visible = false
helpToggle.Parent = screenGui
local helpToggleCorner = Instance.new("UICorner")
helpToggleCorner.CornerRadius = UDim.new(0, 8)
helpToggleCorner.Parent = helpToggle

local countdownCard = makeFrame(screenGui, "CountdownCard", UDim2.fromOffset(420, 186), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.01)
local countdownTitle = makeLabel(countdownCard, "Title", "Partida iniciando", UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 18), Enum.Font.GothamBlack, 25, theme.TextColor, Enum.TextXAlignment.Center)
local countdownValue = makeLabel(countdownCard, "Value", tostring(Config.Match.CountdownSeconds), UDim2.new(1, -24, 0, 62), UDim2.fromOffset(12, 56), Enum.Font.GothamBlack, 48, theme.WarningColor, Enum.TextXAlignment.Center)
makeLabel(countdownCard, "Body", Config.UI.Onboarding.StartingText, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 124), Enum.Font.GothamBold, 16, theme.MutedTextColor, Enum.TextXAlignment.Center)
countdownCard.Visible = false

local resultBanner = makeFrame(screenGui, "ResultBanner", UDim2.fromOffset(620, 108), UDim2.new(0.5, 0, 0.22, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.01)
local resultText = makeLabel(resultBanner, "ResultText", "", UDim2.new(1, -24, 1, -20), UDim2.fromOffset(12, 10), Enum.Font.GothamBlack, 26, theme.TextColor, Enum.TextXAlignment.Center)
resultBanner.Visible = false

local announcement = makeLabel(screenGui, "Announcement", "", UDim2.fromOffset(560, 48), UDim2.new(0.5, 0, 1, -100), Enum.Font.GothamBlack, 19, theme.TextColor, Enum.TextXAlignment.Center)
announcement.AnchorPoint = Vector2.new(0.5, 1)
announcement.BackgroundColor3 = theme.PanelColor
announcement.BackgroundTransparency = 0.08
announcement.Visible = false
local announcementCorner = Instance.new("UICorner")
announcementCorner.CornerRadius = UDim.new(0, 8)
announcementCorner.Parent = announcement

local shopFrame, shopStroke = makeFrame(screenGui, "ShopFrame", UDim2.fromOffset(620, 430), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5), theme.BackgroundColor, 0.01)
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
itemGrid.CellSize = UDim2.fromOffset(286, 78)
itemGrid.Parent = itemHolder

local currentShopKind = "Items"
local currentItems = {}
local currentCategory = "Todos"
local currentPhase = "Lobby"
local currentMatchState = "Waiting"
local currentResources = { Iron = 0, Gold = 0, Emerald = 0 }
local currentUpgrades = { sharpness = 0, protection = 0, forge = 1 }
local currentRoundFormatLabel = ""
local currentRoundMode = "Solo1v1"
local currentHelpText = ""
local currentObjectiveStep = 0
local currentObjectiveTitle = ""
local currentObjectiveHint = ""
local currentObjectiveTarget = ""
local currentRecommendedStarterItemId = nil
local currentRecommendedStarterReason = ""

clearBaseHighlights = function()
    for _, highlight in ipairs(activeHighlights) do
        if highlight.Parent then
            highlight:Destroy()
        end
    end
    table.clear(activeHighlights)
end

local function addHighlight(part, color)
    if not part or not part:IsA("BasePart") then
        return
    end
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0.05
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Parent = screenGui
    activeHighlights[#activeHighlights + 1] = highlight
end

local function showBaseGuidance(teamId)
    if not teamId or baseGuideShownForTeam[teamId] then
        return
    end
    local world = Workspace:FindFirstChild("CSFanZone")
    local base = world and world:FindFirstChild(teamId)
    if not base then
        return
    end

    clearBaseHighlights()
    addHighlight(base:FindFirstChild("TotemFlag") or base:FindFirstChild("Core"), theme.SuccessColor)
    addHighlight(base:FindFirstChild("ItemShop"), theme.AccentColor)
    addHighlight(base:FindFirstChild("UpgradeShop"), Color3.fromRGB(180, 134, 255))
    local generators = base:FindFirstChild("Generators")
    if generators then
        addHighlight(generators:FindFirstChild("BaseIron"), theme.MutedTextColor)
        addHighlight(generators:FindFirstChild("BaseGold"), theme.WarningColor)
    end
    for _, child in ipairs(base:GetChildren()) do
        if child:IsA("BasePart") and child.Name:match("^RouteMarker") then
            addHighlight(child, theme.AccentColor)
        elseif child:IsA("Folder") and child.Name:match("RouteMouth") then
            local apron = child:FindFirstChild("Apron")
            if apron and apron:IsA("BasePart") then
                addHighlight(apron, theme.AccentColor)
            end
        end
    end
    baseGuideShownForTeam[teamId] = true
    showAnnouncement(Config.UI.Hints.FirstBase, theme.AccentColor, 5)
    task.delay(10, clearBaseHighlights)
end

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
    task.delay(4, function()
        if sound.Parent then
            sound:Destroy()
        end
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

local function getDisplayedHelpText()
    local remaining = math.max(0, math.ceil(respawnCountdownEndsAt - os.clock()))
    if remaining > 0 then
        return string.format("Respawn em %ds. Prepare a proxima saida.", remaining)
    end
    return currentHelpText
end

local function updateRespawnStatusLabel()
    local remaining = math.max(0, math.ceil(respawnCountdownEndsAt - os.clock()))
    if remaining > 0 then
        upgradeLabel.Text = string.format("Respawn: em %ds", remaining)
        upgradeLabel.TextColor3 = theme.WarningColor
    elseif coreLabel.TextColor3 == theme.DangerColor then
        upgradeLabel.Text = "Respawn: desligado"
        upgradeLabel.TextColor3 = theme.MutedTextColor
    else
        upgradeLabel.Text = "Respawn: ativo"
        upgradeLabel.TextColor3 = theme.MutedTextColor
    end
end

local function showAnnouncement(message, color, duration, priorityName)
    local now = os.clock()
    local priority = announcementPriorities[priorityName or "info"] or announcementPriorities.info
    if announcement.Visible and now < activeAnnouncementExpiresAt and priority < activeAnnouncementPriority then
        return
    end

    announcementToken += 1
    local token = announcementToken
    announcement.Text = message or ""
    announcement.TextColor3 = color or theme.TextColor
    announcement.Visible = announcement.Text ~= ""
    activeAnnouncementPriority = priority
    activeAnnouncementExpiresAt = now + (duration or 3)
    task.delay(duration or 3, function()
        if token == announcementToken then
            announcement.Visible = false
            activeAnnouncementPriority = 0
            activeAnnouncementExpiresAt = 0
        end
    end)
end

local function updateMissionCard()
    if currentObjectiveStep and currentObjectiveStep > 0 then
        missionStepLabel.Text = string.format("Passo %d/6", currentObjectiveStep)
        missionTitleLabel.Text = currentObjectiveTitle ~= "" and currentObjectiveTitle or "Proxima missao"
        missionHintLabel.Text = currentObjectiveHint
        missionTargetLabel.Text = currentObjectiveTarget ~= "" and ("Alvo: " .. currentObjectiveTarget) or ""
    else
        missionStepLabel.Text = "Lobby"
        missionTitleLabel.Text = "Espere a rodada"
        missionHintLabel.Text = Config.UI.KidHelpMessages.Lobby
        missionTargetLabel.Text = ""
    end
end

local function updatePhaseVisibility()
    local showLobby = currentPhase == "Lobby"
    local showCountdown = showLobby and currentMatchState == "Starting"
    local showCompetitive = currentPhase == "InMatch" or currentPhase == "Spectating"

    onboardingCard.Visible = showLobby and not showCountdown and not onboardingDismissed
    helpToggle.Visible = showLobby and not showCountdown and onboardingDismissed
    countdownCard.Visible = showCountdown
    leftPanel.Visible = showCompetitive
    standingsPanel.Visible = showCompetitive and currentActiveTeamCount > 1
    resourceBar.Visible = showCompetitive and currentPhase == "InMatch"
    helpRibbon.Visible = getDisplayedHelpText() ~= "" and (currentPhase ~= "Lobby" or onboardingDismissed)
    missionCard.Visible = currentPhase == "InMatch"
end

missionCard = makeFrame(screenGui, "MissionCard", UDim2.fromOffset(420, 118), UDim2.new(0.5, 0, 0, 146), Vector2.new(0.5, 0), theme.BackgroundColor, 0.01)
missionStepLabel = makeLabel(missionCard, "Step", "Passo 1", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 10), Enum.Font.GothamBold, 14, theme.WarningColor, Enum.TextXAlignment.Center)
missionTitleLabel = makeLabel(missionCard, "Title", "Pegue Ferro", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 30), Enum.Font.GothamBlack, 24, theme.TextColor, Enum.TextXAlignment.Center)
missionHintLabel = makeLabel(missionCard, "Hint", "", UDim2.new(1, -24, 0, 42), UDim2.fromOffset(12, 60), Enum.Font.GothamBold, 14, theme.MutedTextColor, Enum.TextXAlignment.Center)
missionTargetLabel = makeLabel(missionCard, "Target", "", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 96), Enum.Font.GothamBold, 13, theme.AccentColor, Enum.TextXAlignment.Center)
missionCard.Visible = false

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

local function getMissingResourceMessage(resourceType, cost)
    local label = Config.UI.ResourceLabels[resourceType] or resourceType or "Recurso"
    local missing = math.max(0, (cost or 0) - (currentResources[resourceType] or 0))
    return string.format("Faltam %d %s.", missing, label)
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
            local recommendedNow = currentShopKind == "Items" and currentRecommendedStarterItemId == item.Id

            local button = Instance.new("TextButton")
            button.TextWrapped = true
            button.Font = Enum.Font.GothamBold
            button.TextSize = 14
            button.TextColor3 = theme.TextColor
            button.BackgroundColor3 = recommendedNow and theme.SuccessColor or (affordable and theme.AccentColor or theme.PanelColor)
            button.AutoButtonColor = affordable
            local labelText = maxed and (item.DisplayName .. "\nMAX") or string.format("%s\n%s %d", item.DisplayName, Config.UI.ResourceLabels[item.ResourceType] or item.ResourceType, cost or 0)
            if recommendedNow then
                labelText = labelText .. "\nAGORA"
            elseif currentShopKind == "Items" and (item.Id == Config.UI.StarterRecommendations.BlockItemId or item.Id == Config.UI.StarterRecommendations.SwordItemId) then
                labelText = labelText .. "\nBOM INICIO"
            elseif currentShopKind == "Items" and item.Id == Config.UI.StarterRecommendations.PickaxeItemId then
                labelText = labelText .. "\nATAQUE"
            end
            button.Text = labelText
            button.Parent = itemHolder
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button

            button.MouseButton1Click:Connect(function()
                if maxed then
                    pulse(button, theme.DangerColor)
                    playConfiguredSound(Config.Audio.ErrorSoundId)
                    showAnnouncement("Esse upgrade ja esta no maximo.", theme.DangerColor, 2.5, "warning")
                    return
                end
                if not affordable then
                    pulse(button, theme.DangerColor)
                    playConfiguredSound(Config.Audio.ErrorSoundId)
                    showAnnouncement(getMissingResourceMessage(item.ResourceType, cost), theme.WarningColor, 2.5, "info")
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

onboardingClose.MouseButton1Click:Connect(function()
    onboardingDismissed = true
    updatePhaseVisibility()
end)

helpToggle.MouseButton1Click:Connect(function()
    onboardingDismissed = false
    remotes.TelemetryRequested:FireServer({
        EventName = "ftue_open_help",
    })
    updatePhaseVisibility()
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
        title.Text = currentShopKind == "Items" and "Loja de Itens" or "Upgrades do Time"
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
    currentRecommendedStarterItemId = payload.RecommendedStarterItemId
    currentRecommendedStarterReason = payload.RecommendedStarterReason or ""
    currentObjectiveStep = payload.CurrentObjectiveStep or currentObjectiveStep
    currentObjectiveTitle = payload.ObjectiveTitle or currentObjectiveTitle
    currentObjectiveHint = payload.ObjectiveHint or currentObjectiveHint
    currentObjectiveTarget = payload.ObjectiveTarget or currentObjectiveTarget

    teamLabel.Text = "Time: " .. getTeamDisplayName(payload.OwnTeamId)
    coreLabel.Text = string.format("Totem: %s (%d)", payload.TotemDisplayState or (payload.OwnCoreAlive and "Ativo" or "Destruido"), payload.OwnCoreHealth or 0)
    coreLabel.TextColor3 = payload.OwnCoreAlive and theme.SuccessColor or theme.DangerColor
    formatLabel.Text = currentRoundFormatLabel ~= "" and currentRoundFormatLabel or "Formato: --"
    local hints = payload.OwnLoadoutHints or {}
    loadoutHint1.Text = currentRecommendedStarterReason ~= "" and currentRecommendedStarterReason or (hints[1] or "")
    loadoutHint2.Text = currentRecommendedStarterReason ~= "" and (hints[1] or "") or (hints[2] or "")
    loadoutHint3.Text = ""
    if currentPhase == "InMatch" then
        showBaseGuidance(payload.OwnTeamId)
    end
    if shopFrame.Visible then
        buildShopButtons()
    end

    local standings = payload.Standings or {}
    for index, row in ipairs(standingRows) do
        local standing = standings[index]
        if standing then
            row.Text = string.format("  %s | vivos %d | totem %s", standing.BiomeDisplayName, standing.AlivePlayers, standing.CoreAlive and "ativo" or "quebrado")
            row.TextColor3 = standing.Color or theme.TextColor
            row.BackgroundTransparency = standing.CoreAlive and 0.18 or 0.56
        else
            row.Text = "-"
            row.TextColor3 = theme.MutedTextColor
        end
    end

    updateRespawnStatusLabel()
    updateMissionCard()
    updatePhaseVisibility()
end)

remotes.MatchStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    local previousPhase = currentPhase
    currentPhase = payload.PlayerPhase or currentPhase
    currentMatchState = payload.MatchState or currentMatchState
    currentActiveTeamCount = payload.ActiveTeamCount or currentActiveTeamCount
    currentRoundFormatLabel = payload.RoundFormatLabel or ""
    currentRoundMode = payload.RoundMode or currentRoundMode
    currentHelpText = payload.HelpText or ""
    currentObjectiveStep = payload.CurrentObjectiveStep or currentObjectiveStep
    currentObjectiveTitle = payload.ObjectiveTitle or currentObjectiveTitle
    currentObjectiveHint = payload.ObjectiveHint or currentObjectiveHint
    currentObjectiveTarget = payload.ObjectiveTarget or currentObjectiveTarget

    if previousPhase == "Lobby" and currentPhase ~= "Lobby" then
        onboardingDismissed = true
    elseif currentPhase == "Lobby" and previousPhase ~= "Lobby" then
        table.clear(baseGuideShownForTeam)
        clearBaseHighlights()
    end

    stateLabel.Text = Config.UI.MatchStateLabels[currentMatchState] or currentMatchState
    standingsTitle.Text = currentRoundMode == "Duos" and "Duplas" or "Times 1v1"
    onboardingSubtitle.Text = currentHelpText
    local objectives = payload.ObjectiveText or Config.UI.Onboarding.Objectives
    for index, row in ipairs(objectiveRows) do
        row.Text = string.format("%d. %s", index, objectives[index] or "")
    end
    queueLabel.Text = string.format("Fila: %d/%d jogadores", payload.QueueCount or 0, payload.MinPlayersToStart or Config.Match.MinPlayersToStart)
    formatQueueLabel.Text = (payload.RoundFormatLabel or "")
        .. (((payload.PlayersNeededForNextRecommendedFormat or 0) > 0)
            and ("  |  " .. string.format("Falta %d jogador(es) para iniciar", payload.PlayersNeededForNextRecommendedFormat or 0))
            or "  |  Pronto para iniciar")
    helpRibbonText.Text = getDisplayedHelpText()
    updateMissionCard()

    local remaining = payload.RemainingSeconds or math.max(0, (payload.StateEndsAt or 0) - os.time())
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

    updateRespawnStatusLabel()
    updatePhaseVisibility()
end)

remotes.RespawnStateUpdated.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    if payload.Spectating then
        respawnCountdownEndsAt = 0
        currentPhase = "Spectating"
        showAnnouncement(Config.UI.Hints.Spectating, theme.DangerColor, 4, "danger")
    else
        respawnCountdownEndsAt = os.clock() + (payload.RespawnIn or 0)
        showAnnouncement(string.format("%s Respawn em %ds", Config.UI.Hints.RespawnActive, payload.RespawnIn or 0), theme.WarningColor, 3, "warning")
    end
    helpRibbonText.Text = getDisplayedHelpText()
    updateRespawnStatusLabel()
    updatePhaseVisibility()
end)

remotes.AnnouncementPushed.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end
    local priorityName = payload.ColorName == "Danger" and "danger"
        or payload.ColorName == "Warning" and "warning"
        or "info"
    showAnnouncement(payload.Message or "", getThemeColor(payload.ColorName), 4, priorityName)
end)

remotes.FeedbackPushed.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end

    if payload.Type == "ResourceCollected" and payload.ResourceType and resourceLabels[payload.ResourceType] then
        pulse(resourceLabels[payload.ResourceType].Frame, theme.SuccessColor)
        playConfiguredSound(Config.Audio.PickupSoundId)
        if not seenFeedbackHints[payload.ResourceType] then
            seenFeedbackHints[payload.ResourceType] = true
            local hintByResource = {
                Iron = Config.UI.Hints.FirstIron,
                Gold = Config.UI.Hints.FirstGold,
                Emerald = Config.UI.Hints.FirstEmerald,
            }
            showAnnouncement(hintByResource[payload.ResourceType] or "", theme.AccentColor, 3, "info")
        end
    elseif payload.Type == "PurchaseSuccess" then
        pulse(shopFrame, theme.SuccessColor)
        playConfiguredSound(Config.Audio.PurchaseSoundId)
        if payload.Message then
            showAnnouncement(payload.Message, theme.SuccessColor, 2.5, "info")
        end
        if payload.ItemId == Config.UI.StarterRecommendations.PickaxeItemId and not seenFeedbackHints.FirstPickaxe then
            seenFeedbackHints.FirstPickaxe = true
            showAnnouncement(Config.UI.Hints.FirstPickaxe, theme.AccentColor, 4, "info")
        end
    elseif payload.Type == "PurchaseDenied" then
        pulse(shopFrame, theme.DangerColor)
        playConfiguredSound(Config.Audio.ErrorSoundId)
        showAnnouncement(payload.Message or "Acao recusada", theme.DangerColor, 2.5, "warning")
    elseif payload.Type == "UpgradeApplied" then
        pulse(leftPanel, theme.SuccessColor)
        playConfiguredSound(Config.Audio.UpgradeSoundId)
        if payload.Message then
            showAnnouncement(payload.Message, theme.SuccessColor, 2.5, "info")
        end
    elseif payload.Type == "InfoMessage" then
        showAnnouncement(payload.Message or "", theme.AccentColor, 3.5, "info")
    elseif payload.Type == "FirstStarterPurchase" then
        showAnnouncement("Boa. Agora use esse item para o proximo passo.", theme.SuccessColor, 3, "info")
    elseif payload.Type == "FirstBridgeBuilt" then
        showAnnouncement(payload.Message or Config.UI.Hints.FirstBridge, theme.SuccessColor, 3.5, "info")
    elseif payload.Type == "FirstMiddleReached" then
        showAnnouncement(payload.Message or Config.UI.Hints.ReachMiddle, theme.SuccessColor, 3.5, "info")
    elseif payload.Type == "CoreHit" then
        if payload.Role == "Defender" then
            showAnnouncement("Seu totem esta sob ataque", theme.WarningColor, 2.5, "warning")
        else
            showAnnouncement("Totem inimigo atingido", theme.WarningColor, 2.2, "warning")
        end
        playConfiguredSound(Config.Audio.CoreHitSoundId)
    elseif payload.Type == "CoreDestroyed" then
        showAnnouncement(Config.UI.Hints.CoreDestroyed, theme.DangerColor, 4, "danger")
        playConfiguredSound(Config.Audio.CoreBreakSoundId)
    end
end)

task.spawn(function()
    while screenGui.Parent do
        if respawnCountdownEndsAt > 0 then
            if os.clock() >= respawnCountdownEndsAt then
                respawnCountdownEndsAt = 0
            end
            helpRibbonText.Text = getDisplayedHelpText()
            updateRespawnStatusLabel()
            updatePhaseVisibility()
        end
        task.wait(0.2)
    end
end)

updatePhaseVisibility()
