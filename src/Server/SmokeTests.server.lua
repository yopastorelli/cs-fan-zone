local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
    return
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VisualKit = require(Shared:WaitForChild("VisualKit"))
local WorldData = require(Shared:WaitForChild("WorldData"))
local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

TestService:Check(#Config.Teams == 6, "exactly six teams configured", script, 1)
TestService:Check(type(Config.Match.MinTeamsToStart) == "number" and Config.Match.MinTeamsToStart == 2, "min teams to start locked", script, 2)
TestService:Check(type(Config.Match.AllowPartialTeams) == "boolean" and Config.Match.AllowPartialTeams == false, "partial teams disabled", script, 3)
TestService:Check(type(Config.Match.SupportedTeamCounts) == "table" and #Config.Match.SupportedTeamCounts == 5 and Config.Match.SupportedTeamCounts[1] == 2 and Config.Match.SupportedTeamCounts[5] == 6, "adaptive team counts configured", script, 4)
TestService:Check(Config.Match.MaxPlayers == 12, "max active players supports six duplas", script, 41)
TestService:Check(Config.Match.MinPlayersToStart == 2, "two players required to start", script, 42)
TestService:Check(Config.Match.PlayersPerTeam == 2, "default players per team is duplas", script, 43)
TestService:Check(Config.Match.PreferredPlayersPerTeam == 2, "preferred players per team matches duplas", script, 44)
TestService:Check(Config.Teams[1].Id == "planicie" and Config.Teams[2].Id == "selva", "first active teams are opposite bases", script, 45)
TestService:Check(Config.Compliance.AllowRealNames == false, "real names disabled", script, 46)
TestService:Check(#WorldData.MidIslands == 6, "exactly six middle islands configured", script, 2)
TestService:Check(WorldData.MidIslands[1].ActiveDuelLane == true and WorldData.MidIslands[4].ActiveDuelLane == true, "1v1 middle lane is highlighted", script, 47)
TestService:Check((Config.Teams[2].BasePosition - Config.Teams[1].BasePosition).Magnitude < 560, "1v1 active bases use shortened route", script, 48)
TestService:Check(#Config.TeamUpgrades.Items >= 3, "at least three upgrades configured", script, 3)
TestService:Check(#Config.Shop.Items >= 4, "at least four shop items configured", script, 4)
TestService:Check(Config.Match.JoinMidMatchPolicy == "LobbyUntilNextRound", "late join policy locked", script, 5)
TestService:Check(type(ArenaState.IsTeamActive) == "function", "active team guard exposed", script, 6)
TestService:Check(type(ArenaState.GetEligiblePlayers) == "function", "eligible queue API exposed", script, 7)
TestService:Check(type(ArenaState.ResolveRoundFormatForPlayers) == "function", "round format resolver exposed", script, 71)
TestService:Check(Config.Audio.PickupSoundId ~= "rbxassetid://0" and Config.Audio.CoreHitSoundId ~= "rbxassetid://0", "nonzero feedback sounds configured", script, 8)

local function checkRoundFormat(playerCount, expectedMode, expectedTeams, expectedPlayersPerTeam, expectedLimit, line)
    local format = ArenaState.ResolveRoundFormatForPlayers(playerCount)
    TestService:Check(format.Mode == expectedMode, "round mode for " .. tostring(playerCount) .. " players", script, line)
    TestService:Check(format.TeamCount == expectedTeams, "team count for " .. tostring(playerCount) .. " players", script, line + 1)
    TestService:Check(format.PlayersPerTeam == expectedPlayersPerTeam, "players per team for " .. tostring(playerCount) .. " players", script, line + 2)
    TestService:Check(format.PlayerLimit == expectedLimit, "player limit for " .. tostring(playerCount) .. " players", script, line + 3)
end

checkRoundFormat(2, "Solo1v1", 2, 1, 2, 1800)
checkRoundFormat(3, "Solo1v1", 2, 1, 2, 1810)
checkRoundFormat(4, "Duos", 2, 2, 4, 1820)
checkRoundFormat(5, "Duos", 2, 2, 4, 1830)
checkRoundFormat(6, "Duos", 3, 2, 6, 1840)
checkRoundFormat(12, "Duos", 6, 2, 12, 1850)

local seenTeams = {}
for index, team in ipairs(Config.Teams) do
    TestService:Check(typeof(team.Id) == "string" and team.Id ~= "", "team id present " .. tostring(index), script, 10 + index)
    TestService:Check(seenTeams[team.Id] ~= true, "team id unique " .. tostring(index), script, 20 + index)
    TestService:Check(typeof(team.BiomeDisplayName) == "string" and team.BiomeDisplayName ~= "", "biome display name present " .. tostring(index), script, 30 + index)
    TestService:Check(team.Members == nil, "team has no configured real-name roster " .. tostring(index), script, 40 + index)
    TestService:Check(string.sub(team.DisplayName, 1, 5) == "Time ", "team display name uses neutral team wording " .. tostring(index), script, 70 + index)
    seenTeams[team.Id] = true
    TestService:Check(Config.Biomes[team.BiomeId] ~= nil, "biome id mapped " .. tostring(index), script, 50 + index)
    TestService:Check(typeof(team.BasePosition) == "Vector3", "team base position configured " .. tostring(index), script, 60 + index)
end

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
    TestService:Check(type(item.ResourceType) == "string" and item.ResourceType ~= "", "upgrade resource defined " .. tostring(index), script, 140 + index)
    seenUpgrades[item.Id] = true
end

TestService:Check(typeof(WorldData.CenterIsland.Position) == "Vector3", "center island configured", script, 150)
TestService:Check(typeof(WorldData.SpectatorDeck.Position) == "Vector3", "spectator deck configured", script, 151)
TestService:Check(typeof(WorldData.Lobby.Position) == "Vector3", "lobby configured", script, 152)
TestService:Check(typeof(Config.World.Lobby.SpawnPosition) == "Vector3", "lobby spawn configured", script, 153)
TestService:Check(type(Config.UI.Onboarding.Objectives) == "table" and #Config.UI.Onboarding.Objectives == 4, "four onboarding objectives configured", script, 154)
TestService:Check(type(Config.UI.Onboarding.ByPhase) == "table", "onboarding by phase configured", script, 1541)
TestService:Check(type(Config.UI.Hints) == "table", "context hints configured", script, 1542)
TestService:Check(type(Config.UI.StarterRecommendations) == "table", "starter recommendations configured", script, 1543)
TestService:Check(type(Config.UI.AdaptiveQueueText) == "table", "adaptive queue text configured", script, 1544)
TestService:Check(type(Config.UI.GuidedSteps) == "table" and #Config.UI.GuidedSteps == 6, "guided steps configured", script, 1545)
TestService:Check(type(Config.UI.StarterFlow) == "table", "starter flow configured", script, 1546)
TestService:Check(type(Config.UI.KidHelpMessages) == "table", "kid help messages configured", script, 1547)
TestService:Check(type(Config.UI.ObjectiveIcons) == "table", "objective icon labels configured", script, 1548)
TestService:Check(type(Config.Analytics) == "table", "analytics config present", script, 1549)
TestService:Check(type(Config.Analytics.OnboardingFunnelName) == "string" and Config.Analytics.OnboardingFunnelName ~= "", "onboarding funnel configured", script, 1550)
TestService:Check(type(Config.Visual) == "table", "visual config present", script, 1551)
TestService:Check(Config.Visual.VisualQualityDefault == "Low", "low visual tier is default", script, 1552)
TestService:Check(Config.Visual.AllowStandardVisuals == true, "standard visuals allowed", script, 1553)
TestService:Check(type(Config.UI.HelpMessagesByState.Waiting) == "string", "waiting help message configured", script, 155)
TestService:Check(type(Config.UI.HelpMessagesByState.Spectating) == "string", "spectating help message configured", script, 156)
TestService:Check(type(Config.UI.Results.DrawText) == "string", "draw ui text configured", script, 157)
TestService:Check(type(Config.Interaction.ShopDistance) == "number" and Config.Interaction.ShopDistance > 0, "shop distance configured", script, 158)
TestService:Check(type(Config.Interaction.UpgradeDistance) == "number" and Config.Interaction.UpgradeDistance > 0, "upgrade distance configured", script, 159)
TestService:Check(type(Config.Combat.SpawnProtectionSeconds) == "number" and Config.Combat.SpawnProtectionSeconds > 0, "spawn protection configured", script, 1591)
TestService:Check(type(Remotes.Names.FeedbackPushed) == "string", "feedback remote configured", script, 160)
TestService:Check(type(Remotes.Names.TelemetryRequested) == "string", "telemetry remote configured", script, 1601)
TestService:Check(type(VisualKit.Biomes.planicie) == "table", "planicie visual kit configured", script, 161)
TestService:Check(type(VisualKit.Biomes.deserto) == "table", "deserto visual kit configured", script, 162)
TestService:Check(type(VisualKit.Biomes.taiga) == "table", "taiga visual kit configured", script, 163)
TestService:Check(type(VisualKit.Biomes.selva) == "table", "selva visual kit configured", script, 164)
TestService:Check(type(VisualKit.Biomes.neve) == "table", "neve visual kit configured", script, 165)
TestService:Check(type(VisualKit.Biomes.cogumelos) == "table", "cogumelos visual kit configured", script, 166)
TestService:Check(type(VisualKit.QualityTiers.Low) == "table", "low quality tier configured", script, 167)
TestService:Check(type(VisualKit.QualityTiers.Standard) == "table", "standard quality tier configured", script, 168)
TestService:Check(type(VisualKit.LightingPresets.Low) == "table", "low lighting preset configured", script, 169)
TestService:Check(type(VisualKit.LightingPresets.Standard) == "table", "standard lighting preset configured", script, 170)
TestService:Check(type(VisualKit.VfxBudget.Low) == "table", "low vfx budget configured", script, 171)
TestService:Check(type(VisualKit.BiomeSurfaceRules.planicie) == "table", "biome surface rules configured", script, 172)
TestService:Check(type(ArenaState.GetRoundToken) == "function", "round token getter exposed", script, 1721)

local starterBlockItem
local starterSwordItem
for _, item in ipairs(Config.Shop.Items) do
    if item.Id == Config.UI.StarterFlow.First then
        starterBlockItem = item
    elseif item.Id == Config.UI.StarterFlow.Second then
        starterSwordItem = item
    end
end

TestService:Check(starterBlockItem ~= nil, "starter block item exists", script, 1722)
TestService:Check(starterSwordItem ~= nil, "starter sword item exists", script, 1723)
TestService:Check(
    starterBlockItem ~= nil and Config.UI.GuidedSteps[3].Target == starterBlockItem.DisplayName,
    "guided step target matches starter block display name",
    script,
    1724
)
TestService:Check(
    starterBlockItem ~= nil and string.find(Config.UI.GuidedSteps[3].Hint, starterBlockItem.DisplayName, 1, true) ~= nil,
    "guided step hint matches starter block display name",
    script,
    1725
)
TestService:Check(
    starterSwordItem ~= nil and Config.UI.StarterRecommendations.SwordItemId == starterSwordItem.Id,
    "starter sword recommendation matches shop config",
    script,
    1726
)

local world = Workspace:WaitForChild("CSFanZone", 10)
TestService:Check(world ~= nil, "world exists in workspace", script, 173)

if world then
    local pointLightCount = 0
    local particleEmitterCount = 0
    local billboardCount = 0
    local surfaceGuiCount = 0
    local baseCount = 0
    local middleTriggerCount = 0
    local centerEmeraldCount = 0
    local queueStatusSignFound = false
    local tacticalBoardFound = false
    local minimapBoardFound = false
    local activeDuelLaneCount = 0

    for _, descendant in ipairs(world:GetDescendants()) do
        if descendant:IsA("PointLight") then
            pointLightCount += 1
        elseif descendant:IsA("ParticleEmitter") then
            particleEmitterCount += 1
        elseif descendant:IsA("BillboardGui") then
            billboardCount += 1
        elseif descendant:IsA("SurfaceGui") then
            surfaceGuiCount += 1
        elseif descendant:IsA("Folder") and Config.Biomes[descendant.Name] ~= nil and descendant.Parent == world then
            baseCount += 1
        elseif descendant:IsA("BasePart") and descendant:GetAttribute("MiddleIslandTrigger") == true then
            middleTriggerCount += 1
        elseif descendant:IsA("BasePart") and descendant:GetAttribute("GeneratorType") == "MidEmerald" and descendant.Name:match("^CenterEmerald") then
            centerEmeraldCount += 1
        elseif descendant:IsA("BasePart") and descendant.Name == "QueueStatusSign" then
            queueStatusSignFound = true
        elseif descendant:IsA("BasePart") and descendant.Name == "TacticalBoard" then
            tacticalBoardFound = true
        elseif descendant:IsA("BasePart") and descendant.Name == "MiniMapBoard" then
            minimapBoardFound = true
        elseif descendant:IsA("Folder") and descendant:GetAttribute("ActiveDuelLane") == true then
            activeDuelLaneCount += 1
        end
    end

    local lowBudget = VisualKit.VfxBudget.Low
    TestService:Check(baseCount == 6, "six base folders generated", script, 174)
    TestService:Check(middleTriggerCount == 6, "six middle triggers generated", script, 175)
    TestService:Check(centerEmeraldCount == 3, "three center emerald generators generated", script, 176)
    TestService:Check(activeDuelLaneCount == 2, "two active 1v1 middle lanes highlighted", script, 1760)
    TestService:Check(queueStatusSignFound, "queue status sign generated", script, 1761)
    TestService:Check(tacticalBoardFound, "tactical board generated", script, 1762)
    TestService:Check(minimapBoardFound, "minimap board generated", script, 1763)
    TestService:Check(pointLightCount <= lowBudget.PermanentPointLights, "point light budget respected", script, 177)
    TestService:Check(particleEmitterCount <= lowBudget.PermanentParticleEmitters, "particle budget respected", script, 178)
    TestService:Check(billboardCount <= lowBudget.AlwaysOnBillboards, "billboard budget respected", script, 179)
    TestService:Check(surfaceGuiCount <= lowBudget.DoubleSurfaceSigns * 2, "surface gui budget respected", script, 180)
end
