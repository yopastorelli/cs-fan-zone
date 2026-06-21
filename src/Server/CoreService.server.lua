local Workspace = game:GetService("Workspace")

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local world = Workspace:WaitForChild("CSFanZone")
for _, descendant in ipairs(world:GetDescendants()) do
    if descendant:IsA("BasePart") and descendant.Name == "Core" then
        local teamId = descendant:GetAttribute("CoreTeamId")
        if teamId then
            ArenaState.RegisterCore(teamId, descendant)
        end
    end
end
