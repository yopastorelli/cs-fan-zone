local Players = game:GetService("Players")

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

Players.PlayerAdded:Connect(function(player)
    ArenaState.GetPlayerState(player)
    ArenaState.BroadcastMatchState()
end)

Players.PlayerRemoving:Connect(function(player)
    ArenaState.Players[player] = nil
    ArenaState.BroadcastMatchState()
end)

for _, player in ipairs(Players:GetPlayers()) do
    ArenaState.GetPlayerState(player)
end
