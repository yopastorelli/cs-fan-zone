local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

if not RunService:IsStudio() then
    return
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Counter = require(Shared:WaitForChild("Counter"))

local state = Counter.new(3)
TestService:Check(state.count == 0, "counter starts at zero", script, 1)
TestService:Check(Counter.isComplete(state) == false, "counter does not start complete", script, 2)

local firstCollectChanged = Counter.collect(state, "a")
local duplicateCollectChanged = Counter.collect(state, "a")
TestService:Check(firstCollectChanged == true, "first collect changes state", script, 3)
TestService:Check(duplicateCollectChanged == false, "duplicate collect does not change state", script, 4)
TestService:Check(state.count == 1, "duplicate collect is not counted", script, 5)

Counter.collect(state, "b")
Counter.collect(state, "c")
TestService:Check(Counter.isComplete(state) == true, "counter completes at goal", script, 6)
