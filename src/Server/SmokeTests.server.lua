local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

if not RunService:IsStudio() then
    return
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldData = require(Shared:WaitForChild("WorldData"))

TestService:Check(#Config.Teams == 6, "exactly six teams configured", script, 1)
TestService:Check(#WorldData.MidIslands == 6, "exactly six mid islands configured", script, 2)
TestService:Check(#Config.TeamUpgrades.Items >= 3, "at least three upgrades configured", script, 3)
TestService:Check(#Config.Shop.Items >= 4, "at least four shop items configured", script, 4)

local seenTeams = {}
local totalMembers = 0
for index, team in ipairs(Config.Teams) do
    TestService:Check(typeof(team.Id) == "string" and team.Id ~= "", "team id present " .. tostring(index), script, 10 + index)
    TestService:Check(seenTeams[team.Id] ~= true, "team id unique " .. tostring(index), script, 20 + index)
    TestService:Check(typeof(team.BiomeDisplayName) == "string" and team.BiomeDisplayName ~= "", "biome display name present " .. tostring(index), script, 30 + index)
    TestService:Check(#team.Members == 2, "team has two members " .. tostring(index), script, 40 + index)
    seenTeams[team.Id] = true
    totalMembers += #team.Members
    TestService:Check(Config.Biomes[team.BiomeId] ~= nil, "biome id mapped " .. tostring(index), script, 50 + index)
end

TestService:Check(totalMembers == 12, "twelve roster slots configured", script, 70)

local seenShopItems = {}
for index, item in ipairs(Config.Shop.Items) do
    TestService:Check(seenShopItems[item.Id] ~= true, "shop item unique " .. tostring(index), script, 80 + index)
    TestService:Check(type(item.Cost) == "number" and item.Cost > 0, "shop item cost valid " .. tostring(index), script, 90 + index)
    TestService:Check(Config.Generators.ResourceDefinitions[item.ResourceType] ~= nil, "shop item resource valid " .. tostring(index), script, 100 + index)
    seenShopItems[item.Id] = true
end

local seenUpgrades = {}
for index, item in ipairs(Config.TeamUpgrades.Items) do
    TestService:Check(seenUpgrades[item.Id] ~= true, "upgrade unique " .. tostring(index), script, 120 + index)
    TestService:Check(#item.TierCosts == #item.EffectValues, "upgrade tiers aligned " .. tostring(index), script, 130 + index)
    seenUpgrades[item.Id] = true
end

TestService:Check(typeof(WorldData.CenterIsland.Position) == "Vector3", "center island configured", script, 150)
TestService:Check(typeof(WorldData.SpectatorDeck.Position) == "Vector3", "spectator deck configured", script, 151)
