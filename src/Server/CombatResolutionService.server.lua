local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

while true do
    task.wait(1)

    if ArenaState.MatchState == "Active" or ArenaState.MatchState == "SuddenDeath" then
        local remainingTeams = ArenaState.GetRemainingTeams()
        if #remainingTeams == 1 then
            local winningTeam = remainingTeams[1]
            ArenaState.RecordWin(winningTeam.Id)
            ArenaState.SetMatchResult("Victory", winningTeam.Id)
            ArenaState.PushAnnouncement(string.format(Config.UI.Messages.VictoryAnnouncement, winningTeam.DisplayName), "Success")
            ArenaState.SetMatchState("Ended", Config.Match.PostMatchSeconds, {
                EndReason = "Victory",
                WinningTeamId = winningTeam.Id,
            })
        elseif #remainingTeams == 0 then
            ArenaState.SetMatchResult("Draw", nil)
            ArenaState.PushAnnouncement(Config.UI.Messages.DrawAnnouncement, "Warning")
            ArenaState.SetMatchState("Ended", Config.Match.PostMatchSeconds, {
                EndReason = "Draw",
                WinningTeamId = nil,
            })
        end
    end
end
