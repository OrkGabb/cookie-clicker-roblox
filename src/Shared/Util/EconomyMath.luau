--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local CupcakeConfig = require(ReplicatedStorage.Shared.Config.CupcakeConfig)
local EffectRegistry = require(ReplicatedStorage.Shared.ECS.Systems.EffectRegistry)
local Types = require(ReplicatedStorage.Shared.Types)

local EconomyMath = {}

-- Evaluates the live CPC multiplier based on active upgrades
function EconomyMath.ComputeLiveCPC(data: Types.PlayerData): number
	local c = {
		amount = 0,
		perClick = Constants.STARTING_PER_CLICK,
		perSecond = Constants.BASE_PASSIVE,
		clickMultiplier = 1,
		passiveMultiplier = 1,
	}
	
	for _, def in ipairs(UpgradeConfig) do
		local count = data.upgrades[def.id] or 0
		if count > 0 then
			EffectRegistry.apply(def.kind, count, def.basePower, c)
		end
	end
	
	return c.perClick * c.clickMultiplier
end

-- Live passive cookies/second from active upgrades. SSoT mirror of ComputeLiveCPC,
-- used by the server-authoritative passive accrual so it matches client prediction.
function EconomyMath.ComputePassivePerSecond(data: Types.PlayerSaveData): number
	local c = {
		amount = 0,
		perClick = Constants.STARTING_PER_CLICK,
		perSecond = Constants.BASE_PASSIVE,
		clickMultiplier = 1,
		passiveMultiplier = 1,
	}

	for _, def in ipairs(UpgradeConfig) do
		local count = data.upgrades[def.id] or 0
		if count > 0 then
			EffectRegistry.apply(def.kind, count, def.basePower, c)
		end
	end

	return c.perSecond * c.passiveMultiplier
end

function EconomyMath.ComputeUpgradeCost(def: Types.UpgradeDefinition, ownedCount: number): number
	return math.floor(def.baseCost * math.pow(def.costGrowth, ownedCount))
end

-- Cupcake cost for the purchase that takes an upgrade to `newCount` (the resulting
-- level). Milestones land on multiples of 5 (5, 10, 15, ...); milestoneIndex =
-- newCount / 5. Tier-baixo upgrades have no MilestoneCosts entry and thus always
-- return 0. Returns 0 when the purchase is not a milestone or is out of range.
function EconomyMath.ComputeMilestoneCupcakeCost(upgradeId: string, newCount: number): number
	if newCount <= 0 or newCount % 5 ~= 0 then return 0 end
	local costs = CupcakeConfig.MilestoneCosts[upgradeId]
	if not costs then return 0 end
	return costs[newCount // 5] or 0
end

return EconomyMath
