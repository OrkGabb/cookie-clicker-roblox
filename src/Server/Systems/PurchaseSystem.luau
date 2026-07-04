--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local EconomyMath = require(ReplicatedStorage.Shared.Util.EconomyMath)

local PurchaseSystem = {}

function PurchaseSystem.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local requestPurchase = (Remotes :: any).RequestPurchase :: RemoteFunction
	
	requestPurchase.OnServerInvoke = function(player: Player, upgradeId: string)
		if typeof(upgradeId) ~= "string" then return false end
		
		local data = DataService.GetProfileData(player)
		if not data then return false end
		
		local def = nil
		for _, u in ipairs(UpgradeConfig) do
			if u.id == upgradeId then
				def = u
				break
			end
		end
		
		if not def then return false end

		local count = data.upgrades[upgradeId] or 0

		-- CAP enforcement (6.1): never exceed maxStacks.
		if def.maxStacks and count >= def.maxStacks then return false end

		local cost = EconomyMath.ComputeUpgradeCost(def, count)
		-- Milestone cupcake gate (6.3): the purchase that lands on a multiple of 5.
		local cupcakeCost = EconomyMath.ComputeMilestoneCupcakeCost(upgradeId, count + 1)
		if cupcakeCost > 0 and data.cupcake < cupcakeCost then return false end

		local AchievementService = require(script.Parent.AchievementService)

		if DataService.DeductCurrency(player, cost) then
			if cupcakeCost > 0 then
				DataService.DeductCupcake(player, cupcakeCost)
			end
			data.upgrades[upgradeId] = count + 1
			AchievementService.RecordStat(player, "upgradesPurchasedTotal", 1)
			if def.kind == "perClick" then
				AchievementService.RecordStat(player, "upgradesPurchasedClicker", 1)
			elseif def.kind == "passive" then
				AchievementService.RecordStat(player, "upgradesPurchasedPassive", 1)
			end
			-- Quests: unique-upgrade + peak-currency checks (7c).
			require(script.Parent.QuestService).Evaluate(player)
			return true
		end
		
		return false
	end
end

return PurchaseSystem
