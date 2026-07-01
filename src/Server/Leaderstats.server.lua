local Players = game:GetService("Players")

local function getOrCreateStatFolder(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        return leaderstats
    end

    leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    return leaderstats
end

local function getOrCreateIntValue(parent, name)
    local value = parent:FindFirstChild(name)
    if value then
        return value
    end

    value = Instance.new("IntValue")
    value.Name = name
    value.Parent = parent
    return value
end

local function onPlayerAdded(player)
    local leaderstats = getOrCreateStatFolder(player)
    getOrCreateIntValue(leaderstats, "Kills").Value = 0
    getOrCreateIntValue(leaderstats, "FinalKills").Value = 0
    getOrCreateIntValue(leaderstats, "Wins").Value = 0
    getOrCreateIntValue(leaderstats, "TotemsBroken").Value = 0

    player:SetAttribute("TeamId", "")
    player:SetAttribute("CoreAlive", false)
    player:SetAttribute("Eliminated", false)
    player:SetAttribute("InMatch", false)
    player:SetAttribute("PlayerPhase", "Lobby")
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
