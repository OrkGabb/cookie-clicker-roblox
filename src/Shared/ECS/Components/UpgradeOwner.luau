--!strict
local UpgradeOwner = {}
export type UpgradeOwner = {
	counts:          {[string]: number},
	totalOwned:      number,
	uniqueOwned:     number,
	sessionPurchases: number,
}
function UpgradeOwner.new(): UpgradeOwner
	return {
		counts           = {},
		totalOwned       = 0,
		uniqueOwned      = 0,
		sessionPurchases = 0,
	}
end
return UpgradeOwner
