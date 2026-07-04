--!strict
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

function MonetizationService.Init()
	-- Receipt handling moved to ShopService, which is the single owner of
	-- MarketplaceService.ProcessReceipt (idempotent + persisted). Only one callback can
	-- exist, so this service no longer assigns it. CheckGamepass is kept for ownership
	-- lookups against the existing ownedPasses schema field.
end

function MonetizationService.CheckGamepass(player: Player, passId: string): boolean
	local data = DataService.GetProfileData(player)
	if not data then return false end

	for _, pId in ipairs(data.ownedPasses) do
		if pId == passId then return true end
	end

	return false
end

return MonetizationService
