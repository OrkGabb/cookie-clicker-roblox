--!strict
local Currency = {}
export type Currency = {
	amount: number,
	perClick: number,
	perSecond: number,
	clickMultiplier: number,
	passiveMultiplier: number,
}
function Currency.new(): Currency
	return {
		amount           = 0,
		perClick         = 1,
		perSecond        = 0,
		clickMultiplier  = 1,
		passiveMultiplier = 1,
	}
end
return Currency
