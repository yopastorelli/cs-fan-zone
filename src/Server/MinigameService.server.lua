local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local roundStateUpdated = Remotes.GetRemote("RoundStateUpdated")

local INTERMISSION_SECONDS = 10

local function getWinsStat(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    return leaderstats and leaderstats:FindFirstChild("Wins")
end

local function resetRoundState()
    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("RoundCoins", 0)
    end
end

local function findWinners()
    local winners = {}
    local bestScore = -1

    for _, player in ipairs(Players:GetPlayers()) do
        local score = player:GetAttribute("RoundCoins") or 0
        if score > bestScore then
            winners = { player }
            bestScore = score
        elseif score == bestScore then
            winners[#winners + 1] = player
        end
    end

    if bestScore <= 0 then
        return {}, 0
    end

    return winners, bestScore
end

local function announce(payload)
    roundStateUpdated:FireAllClients(payload)
end

task.spawn(function()
    while true do
        announce({
            Phase = "Intermission",
            Remaining = INTERMISSION_SECONDS,
            Duration = INTERMISSION_SECONDS,
            Message = "Prepare-se para a proxima rodada.",
        })

        for remaining = INTERMISSION_SECONDS, 1, -1 do
            announce({
                Phase = "Intermission",
                Remaining = remaining,
                Duration = INTERMISSION_SECONDS,
                Message = "Prepare-se para a proxima rodada.",
            })
            task.wait(1)
        end

        resetRoundState()
        announce({
            Phase = "Active",
            Remaining = Config.RoundDurationSeconds,
            Duration = Config.RoundDurationSeconds,
            Message = "Colete moedas na arena.",
        })

        for remaining = Config.RoundDurationSeconds, 1, -1 do
            announce({
                Phase = "Active",
                Remaining = remaining,
                Duration = Config.RoundDurationSeconds,
                Message = "Colete moedas na arena.",
            })
            task.wait(1)
        end

        local winners, bestScore = findWinners()
        local winnerNames = {}

        for _, winner in ipairs(winners) do
            local wins = getWinsStat(winner)
            if wins then
                wins.Value += 1
            end
            winnerNames[#winnerNames + 1] = winner.Name
        end

        local message
        if #winnerNames == 0 then
            message = "Rodada encerrada sem vencedor."
        else
            message = string.format("Vencedor(es): %s com %d coins.", table.concat(winnerNames, ", "), bestScore)
        end

        announce({
            Phase = "Results",
            Remaining = 0,
            Duration = Config.RoundDurationSeconds,
            Message = message,
            Winners = winnerNames,
            Score = bestScore,
        })

        task.wait(5)
    end
end)
