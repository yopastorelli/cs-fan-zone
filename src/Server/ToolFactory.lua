local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ArenaState = require(script.Parent:WaitForChild("ArenaState"))

local ToolFactory = {}

local function getCharacterRoot(tool)
    local character = tool.Parent
    if not character or not character:IsA("Model") then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then
        return nil, nil, nil
    end

    return character, humanoid, rootPart
end

local function getPlayerFromTool(tool)
    local character = tool.Parent
    if not character then
        return nil
    end
    return Players:GetPlayerFromCharacter(character)
end

local function findEnemyHumanoid(player, rootPart, range, dotThreshold)
    local nearestHumanoid = nil
    local nearestDistance = range + 1

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and ArenaState.IsEnemy(player, otherPlayer) and ArenaState.IsPlayerInMatch(otherPlayer) then
            local otherCharacter = otherPlayer.Character
            local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
            local otherHumanoid = otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")
            if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
                local offset = otherRoot.Position - rootPart.Position
                local distance = offset.Magnitude
                if distance <= range then
                    local direction = offset.Unit
                    if rootPart.CFrame.LookVector:Dot(direction) >= dotThreshold and distance < nearestDistance then
                        nearestHumanoid = otherHumanoid
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    return nearestHumanoid
end

local function markKillCredit(targetHumanoid, attacker)
    targetHumanoid:SetAttribute("LastAttackerUserId", attacker.UserId)
    targetHumanoid:SetAttribute("LastAttackAt", os.clock())
end

local function createHandle(color)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 3, 1)
    handle.Color = color
    handle.Material = Enum.Material.Metal
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    return handle
end

local function canUseMatchTool(player, humanoid)
    return player and humanoid and humanoid.Health > 0 and ArenaState.IsPlayerInMatch(player)
end

function ToolFactory.CreateSwordTool(teamId, itemConfig)
    local tool = Instance.new("Tool")
    tool.Name = itemConfig.DisplayName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("DamageBonus", itemConfig.DamageBonus or 0)
    tool:SetAttribute("TeamId", teamId)

    local handle = createHandle(Color3.fromRGB(133, 144, 160))
    handle.Parent = tool

    local swinging = false
    tool.Activated:Connect(function()
        if swinging then
            return
        end

        local player = getPlayerFromTool(tool)
        local _, humanoid, rootPart = getCharacterRoot(tool)
        if not canUseMatchTool(player, humanoid) then
            return
        end

        swinging = true
        local enemyHumanoid = findEnemyHumanoid(player, rootPart, Config.Combat.SwordHitRange, Config.Combat.SwordHitAngleDot)
        if enemyHumanoid then
            local enemyPlayer = Players:GetPlayerFromCharacter(enemyHumanoid.Parent)
            local damage = Config.Combat.SwordBaseDamage + (tool:GetAttribute("DamageBonus") or 0)
            local teamLevel = ArenaState.GetUpgradeLevel(teamId, "sharpness")
            if teamLevel > 0 and Config.TeamUpgrades.Items[1].EffectValues[teamLevel] then
                damage += Config.TeamUpgrades.Items[1].EffectValues[teamLevel]
            end
            if enemyPlayer then
                local enemyState = ArenaState.GetPlayerState(enemyPlayer)
                local reduction = enemyState.TeamId and ArenaState.GetDamageReduction(enemyState.TeamId) or 0
                damage = math.max(1, math.floor(damage * (1 - reduction)))
            end
            markKillCredit(enemyHumanoid, player)
            enemyHumanoid:TakeDamage(damage)
        end

        task.delay(Config.Combat.SwordCooldownSeconds, function()
            swinging = false
        end)
    end)

    return tool
end

function ToolFactory.CreatePickaxeTool(teamId, itemConfig)
    local tool = Instance.new("Tool")
    tool.Name = itemConfig.DisplayName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("TeamId", teamId)

    local handle = createHandle(Color3.fromRGB(188, 188, 188))
    handle.Size = Vector3.new(1, 2.6, 1)
    handle.Parent = tool

    local coolingDown = false
    tool.Activated:Connect(function()
        if coolingDown then
            return
        end

        local player = getPlayerFromTool(tool)
        local _, humanoid, rootPart = getCharacterRoot(tool)
        if not canUseMatchTool(player, humanoid) then
            return
        end

        coolingDown = true
        local playerState = ArenaState.GetPlayerState(player)
        local targetTeamId = nil
        local targetCore = nil

        for otherTeamId, corePart in pairs(ArenaState.CoreInstances) do
            if otherTeamId ~= playerState.TeamId and corePart.Parent then
                local offset = corePart.Position - rootPart.Position
                if offset.Magnitude <= Config.Combat.PickaxeHitRange and rootPart.CFrame.LookVector:Dot(offset.Unit) >= 0.15 then
                    targetTeamId = otherTeamId
                    targetCore = corePart
                    break
                end
            end
        end

        if targetTeamId and targetCore then
            local _, remainingHealth = ArenaState.DamageCore(targetTeamId, Config.Match.CoreDamagePerHit)
            if remainingHealth <= 0 then
                ArenaState.RecordCoreBreak(player)
                ArenaState.PushAnnouncement(string.format("%s destruiu o nucleo da %s", player.Name, ArenaState.Teams[targetTeamId].DisplayName), "Danger")
                ArenaState.PushFeedback(nil, "CoreDestroyed", {
                    TeamId = targetTeamId,
                    AttackerName = player.Name,
                })
            else
                ArenaState.PushAnnouncement(string.format("%s acertou um nucleo inimigo", player.Name), "Warning")
                ArenaState.PushFeedback(nil, "CoreHit", {
                    TeamId = targetTeamId,
                    AttackerName = player.Name,
                    RemainingHealth = remainingHealth,
                })
            end
        else
            local bounds = Workspace:GetPartBoundsInBox(rootPart.CFrame + (rootPart.CFrame.LookVector * 6), Vector3.new(6, 6, 6))
            for _, part in ipairs(bounds) do
                if part:GetAttribute("PlacedBlock") == true and part:GetAttribute("OwnerTeamId") ~= playerState.TeamId then
                    part:Destroy()
                    break
                end
            end
        end

        task.delay(Config.Combat.PickaxeCooldownSeconds, function()
            coolingDown = false
        end)
    end)

    return tool
end

function ToolFactory.CreateHealTool(teamId, itemConfig)
    local tool = Instance.new("Tool")
    tool.Name = itemConfig.DisplayName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("TeamId", teamId)

    local handle = createHandle(Color3.fromRGB(45, 220, 162))
    handle.Size = Vector3.new(1.4, 2, 1.4)
    handle.Shape = Enum.PartType.Ball
    handle.Parent = tool

    local used = false
    tool.Activated:Connect(function()
        if used then
            return
        end

        local player = getPlayerFromTool(tool)
        local _, humanoid = getCharacterRoot(tool)
        if not canUseMatchTool(player, humanoid) then
            return
        end

        used = true
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (itemConfig.HealAmount or 0))
        tool:Destroy()
    end)

    return tool
end

function ToolFactory.CreateBlockTool(teamId, itemConfig)
    local tool = Instance.new("Tool")
    tool.Name = itemConfig.DisplayName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("TeamId", teamId)
    tool:SetAttribute("Charges", itemConfig.Charges or 0)

    local teamConfig = ArenaState.GetTeamConfig(teamId)
    local handle = createHandle(teamConfig and teamConfig.Color or Color3.fromRGB(255, 255, 255))
    handle.Size = Vector3.new(2, 2, 2)
    handle.Parent = tool

    local placing = false
    tool.Activated:Connect(function()
        if placing then
            return
        end

        local player = getPlayerFromTool(tool)
        local _, humanoid, rootPart = getCharacterRoot(tool)
        if not canUseMatchTool(player, humanoid) then
            return
        end

        local charges = tool:GetAttribute("Charges") or 0
        if charges <= 0 then
            tool:Destroy()
            return
        end

        placing = true
        local targetPosition = rootPart.Position + (rootPart.CFrame.LookVector * Config.Combat.BlockPlacementDistance) + Vector3.new(0, -2, 0)
        local grid = Config.Combat.BlockGrid
        local snapped = Vector3.new(
            math.floor((targetPosition.X / grid) + 0.5) * grid,
            math.floor((targetPosition.Y / grid) + 0.5) * grid,
            math.floor((targetPosition.Z / grid) + 0.5) * grid
        )

        if ArenaState.IsRestrictedPlacementPosition(player, snapped) then
            placing = false
            return
        end

        local occupancy = Workspace:GetPartBoundsInBox(CFrame.new(snapped), Vector3.new(3.6, 3.6, 3.6))
        for _, part in ipairs(occupancy) do
            if part.CanCollide and part.Transparency < 1 and part.Parent ~= tool.Parent then
                placing = false
                return
            end
        end

        local block = Instance.new("Part")
        block.Name = "PlacedBlock"
        block.Size = Vector3.new(grid, grid, grid)
        block.CFrame = CFrame.new(snapped)
        block.Anchored = true
        block.Material = Enum.Material.Fabric
        block.Color = teamConfig and teamConfig.Color or Color3.fromRGB(255, 255, 255)
        block:SetAttribute("PlacedBlock", true)
        block:SetAttribute("OwnerTeamId", teamId)
        block.Parent = Workspace:WaitForChild("CSFanZone")

        charges -= 1
        tool:SetAttribute("Charges", charges)
        if charges <= 0 then
            tool:Destroy()
        end

        task.delay(0.12, function()
            placing = false
        end)
    end)

    return tool
end

function ToolFactory.GrantItem(player, itemConfig)
    local state = ArenaState.GetPlayerState(player)
    if not state.TeamId or not ArenaState.IsPlayerInMatch(player) then
        return false, "Jogador fora da partida"
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        return false, "Backpack nao encontrado"
    end

    local tool
    if itemConfig.GrantType == "SwordTool" then
        tool = ToolFactory.CreateSwordTool(state.TeamId, itemConfig)
    elseif itemConfig.GrantType == "PickaxeTool" then
        tool = ToolFactory.CreatePickaxeTool(state.TeamId, itemConfig)
    elseif itemConfig.GrantType == "HealTool" then
        tool = ToolFactory.CreateHealTool(state.TeamId, itemConfig)
    elseif itemConfig.GrantType == "BlockTool" then
        tool = ToolFactory.CreateBlockTool(state.TeamId, itemConfig)
    end

    if not tool then
        return false, "Item nao suportado"
    end

    tool.Parent = backpack
    return true
end

return ToolFactory
