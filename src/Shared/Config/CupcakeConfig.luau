--!strict
-- SSoT for the Cupcake (CPK) system.
--
-- MilestoneCosts: keyed by upgrade id. Each value is the ordered list of cupcake
-- costs charged when a purchase takes the upgrade INTO level 5, 10, 15, ...
-- (milestoneIndex = newCount / 5). Only tier-alto upgrades (6-10) appear here;
-- tier-baixo upgrades (1-5) are intentionally absent and therefore always cost 0
-- cupcakes (tier-baixo immunity).
local function fill(n: number, value: number): { number }
	local t = table.create(n)
	for i = 1, n do
		t[i] = value
	end
	return t
end

local CupcakeConfig = {
	-- 1 cupcake awarded per this many MANUAL clicks.
	CLICKS_PER_CUPCAKE = 50,

	MilestoneCosts = {
		sugar_sprite       = fill(20, 20), -- cap 100 -> 20 milestones
		moon_mixer         = fill(20, 20),
		cloud_kitchen      = fill(20, 20),
		stardust_sprinkles = fill(20, 20),
		cosmic_patissier   = { 200 },      -- cap 5 -> 1 milestone
	} :: { [string]: { number } },
}

return CupcakeConfig
