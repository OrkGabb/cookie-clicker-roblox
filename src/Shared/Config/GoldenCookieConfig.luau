--!strict
-- SSoT for golden cookie cadence + reward tiers.
-- @author OrkGabb
local GoldenCookieConfig = {
	SpawnIntervalRange = { Min = 45, Max = 90 }, -- production cadence (random 45–90s)
	DescentDuration = 10,
	DescentTolerance = 1.5, -- Server tolerance for ping/lag before expiring

	-- Rarity-weighted reward tiers (Cookie Clicker "Lucky"-style). Reward scales with
	-- the player's current passive cookies/second (CpS) so it stays meaningful at every
	-- stage: reward = max(floor, cpsSeconds * CpS). The flat `floor` only dominates for
	-- brand-new players with near-zero CpS. Weights are out of 100 (roll 1..100).
	RewardTiers = {
		{ name = "Common",   weight = 65, cpsSeconds = 15,   floor = 10 },  -- ~15s of production
		{ name = "Uncommon", weight = 25, cpsSeconds = 60,   floor = 30 },  -- ~1 min
		{ name = "Rare",     weight = 8,  cpsSeconds = 300,  floor = 100 }, -- ~5 min
		{ name = "Jackpot",  weight = 2,  cpsSeconds = 1800, floor = 500 }, -- ~30 min
	},
}

return GoldenCookieConfig
