--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

local Achievements: {Types.AchievementDefinition} = {
	-- Clicks
	{ id = "clicks_1", title = "First Click!", description = "Click the cookie 10 times.", icon = AssetIds.Achievements, statKey = "totalClicks", threshold = 10, rewardType = "Currency", rewardAmount = 50 },
	{ id = "clicks_2", title = "Getting Started", description = "Click the cookie 1,000 times.", icon = AssetIds.Achievements, statKey = "totalClicks", threshold = 1000, rewardType = "Currency", rewardAmount = 5000 },
	{ id = "clicks_3", title = "Clicker Adept", description = "Click the cookie 10,000 times.", icon = AssetIds.Achievements, statKey = "totalClicks", threshold = 10000, rewardType = "Currency", rewardAmount = 50000 },
	{ id = "clicks_4", title = "Carpal Tunnel", description = "Click the cookie 100,000 times.", icon = AssetIds.Achievements, statKey = "totalClicks", threshold = 100000, rewardType = "Cosmetic", rewardAmount = 0, rewardSkinId = "clicker_pro" },

	-- Cookies
	{ id = "cookies_1", title = "Snack Time", description = "Bake 1,000 cookies.", icon = AssetIds.CookieMain, statKey = "lifetimeCookies", threshold = 1000, rewardType = "Currency", rewardAmount = 250 },
	{ id = "cookies_2", title = "Local Bakery", description = "Bake 100,000 cookies.", icon = AssetIds.CookieMain, statKey = "lifetimeCookies", threshold = 100000, rewardType = "Currency", rewardAmount = 25000 },
	{ id = "cookies_3", title = "Industrial Oven", description = "Bake 10,000,000 cookies.", icon = AssetIds.CookieMain, statKey = "lifetimeCookies", threshold = 10000000, rewardType = "Currency", rewardAmount = 2500000 },

	-- Upgrades
	{ id = "upgrades_1", title = "First Upgrade", description = "Buy your first upgrade.", icon = AssetIds.Settings, statKey = "upgradesPurchasedTotal", threshold = 1, rewardType = "Currency", rewardAmount = 100 },
	{ id = "upgrades_2", title = "Tech Enthusiast", description = "Buy 25 upgrades.", icon = AssetIds.Settings, statKey = "upgradesPurchasedTotal", threshold = 25, rewardType = "Currency", rewardAmount = 10000 },
	{ id = "upgrades_3", title = "Automation Empire", description = "Buy 100 upgrades.", icon = AssetIds.Settings, statKey = "upgradesPurchasedTotal", threshold = 100, rewardType = "Cosmetic", rewardAmount = 0, rewardSkinId = "golden" },
	{ id = "upgrades_clicker", title = "Active Baker", description = "Buy 10 click upgrades.", icon = AssetIds.Settings, statKey = "upgradesPurchasedClicker", threshold = 10, rewardType = "Currency", rewardAmount = 5000 },
	{ id = "upgrades_passive", title = "Idle Tycoon", description = "Buy 10 passive upgrades.", icon = AssetIds.Settings, statKey = "upgradesPurchasedPassive", threshold = 10, rewardType = "Currency", rewardAmount = 5000 },

	-- Golden Cookies
	{ id = "golden_1", title = "Lucky Catch", description = "Catch 1 Golden Cookie.", icon = AssetIds.Golden_Cookie, statKey = "goldenCookiesCollected", threshold = 1, rewardType = "Currency", rewardAmount = 500 },
	{ id = "golden_2", title = "Golden Eye", description = "Catch 25 Golden Cookies.", icon = AssetIds.Golden_Cookie, statKey = "goldenCookiesCollected", threshold = 25, rewardType = "Currency", rewardAmount = 25000 },
	{ id = "golden_3", title = "Leprechaun", description = "Catch 100 Golden Cookies.", icon = AssetIds.Golden_Cookie, statKey = "goldenCookiesCollected", threshold = 100, rewardType = "Currency", rewardAmount = 250000 },

	-- Streaks
	{ id = "streak_1", title = "Dedicated", description = "Maintain a 3-day login streak.", icon = AssetIds.DailyReward, statKey = "dailyStreak", threshold = 3, rewardType = "Currency", rewardAmount = 1000 },
	{ id = "streak_2", title = "Addicted", description = "Maintain a 7-day login streak.", icon = AssetIds.DailyReward, statKey = "dailyStreak", threshold = 7, rewardType = "Currency", rewardAmount = 10000 },
}

return Achievements
