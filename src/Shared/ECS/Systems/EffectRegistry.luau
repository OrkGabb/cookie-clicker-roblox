--!strict
local CurrencyComp = require(script.Parent.Parent.Components.Currency)

local EffectRegistry = {}

function EffectRegistry.apply(kind: string, count: number, basePower: number, currency: CurrencyComp.Currency)
	if kind == "perClick" then
		currency.perClick += count * basePower
	elseif kind == "passive" then
		currency.perSecond += count * basePower
	end
end

return EffectRegistry
