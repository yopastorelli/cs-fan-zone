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
    local memories = getOrCreateIntValue(leaderstats, "Memories")
    local pois = getOrCreateIntValue(leaderstats, "POIs")

    memories.Value = 0
    pois.Value = 0

    player:SetAttribute("MemoriesFound", 0)
    player:SetAttribute("POIsActivated", 0)
    player:SetAttribute("MissionComplete", false)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
