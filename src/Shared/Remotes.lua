local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTE_FOLDER_NAME = "CSFanZoneRemotes"

local RemoteNames = {
    MatchStateUpdated = "MatchStateUpdated",
    TeamStateUpdated = "TeamStateUpdated",
    InventoryUpdated = "InventoryUpdated",
    AnnouncementPushed = "AnnouncementPushed",
    FeedbackPushed = "FeedbackPushed",
    ShopOpened = "ShopOpened",
    PurchaseRequested = "PurchaseRequested",
    UpgradeRequested = "UpgradeRequested",
    RespawnStateUpdated = "RespawnStateUpdated",
}

local function ensureFolder()
    local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
    if folder then
        return folder
    end

    if not RunService:IsServer() then
        return ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME)
    end

    folder = Instance.new("Folder")
    folder.Name = REMOTE_FOLDER_NAME
    folder.Parent = ReplicatedStorage
    return folder
end

local function ensureRemoteEvent(name)
    local folder = ensureFolder()
    local remote = folder:FindFirstChild(name)
    if remote then
        return remote
    end

    if not RunService:IsServer() then
        return folder:WaitForChild(name)
    end

    remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = folder
    return remote
end

local Remotes = {
    Names = RemoteNames,
}

function Remotes.GetFolder()
    return ensureFolder()
end

function Remotes.GetRemote(name)
    local resolvedName = RemoteNames[name] or name
    return ensureRemoteEvent(resolvedName)
end

function Remotes.GetAll()
    local all = {}

    for key in pairs(RemoteNames) do
        all[key] = Remotes.GetRemote(key)
    end

    return all
end

if RunService:IsServer() then
    Remotes.GetAll()
end

return Remotes
