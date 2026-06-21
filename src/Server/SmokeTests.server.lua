local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

if not RunService:IsStudio() then
    return
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Counter = require(Shared:WaitForChild("Counter"))
local WorldData = require(Shared:WaitForChild("WorldData"))

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

local function checkUniqueIds(items, fieldName, label, startIndex)
    local seen = {}

    for index, item in ipairs(items) do
        local id = item[fieldName]
        TestService:Check(typeof(id) == "string" and id ~= "", label .. " id is present " .. tostring(index), script, startIndex + index)
        TestService:Check(seen[id] ~= true, label .. " id is unique " .. tostring(index), script, startIndex + 100 + index)
        seen[id] = true
    end
end

TestService:Check(#Config.Collectibles == Config.Mission.CollectibleGoal, "collectible count matches mission goal", script, 10)
TestService:Check(#Config.POIs == Config.Mission.PoiGoal, "poi count matches mission goal", script, 11)
checkUniqueIds(Config.Collectibles, "Id", "collectible", 20)
checkUniqueIds(Config.POIs, "Id", "poi", 60)

for index, collectible in ipairs(Config.Collectibles) do
    TestService:Check(Config.Areas[collectible.Area] ~= nil, "collectible area exists " .. tostring(index), script, 120 + index)
end

for index, poi in ipairs(Config.POIs) do
    TestService:Check(Config.Areas[poi.Area] ~= nil, "poi area exists " .. tostring(index), script, 150 + index)
end

for index, areaName in ipairs(WorldData.AreasInOrder) do
    TestService:Check(Config.Areas[areaName] ~= nil, "world area order references config area " .. tostring(index), script, 180 + index)
end

TestService:Check(typeof(WorldData.FinalRoomAccess.TargetPosition) == "Vector3", "final room access target exists", script, 210)
