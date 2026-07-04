--!strict
-- ⚠️  Replace productId values with your real Roblox IDs from the Creator Hub.
-- GamePass  → MarketplaceService:PromptGamePassPurchase
-- DevProduct → MarketplaceService:PromptProductPurchase

local Types = require(script.Parent.Parent.Types)

local MonetizationConfig: {Types.MonetizationProduct} = {
	{
		id          = "pass_2x",
		name        = "Sugar Rush (2×)",
		description = "Permanently doubles all Starlight Sugar income.",
		robuxPrice  = 199,
		productType = "gamepass",
		productId   = 99000001,   -- REPLACE
		icon        = "⨢",
	},
	{
		id          = "pass_autobaker",
		name        = "Auto-Baker",
		description = "Automatically taps the cookie every 0.5 seconds.",
		robuxPrice  = 149,
		productType = "gamepass",
		productId   = 99000002,   -- REPLACE
		icon        = "⨪",
	},
	{
		id          = "pass_vip",
		name        = "VIP Pâtissier",
		description = "3× income + exclusive Nebula Nougat skin + golden chat badge.",
		robuxPrice  = 499,
		productType = "gamepass",
		productId   = 99000003,   -- REPLACE
		icon        = "⪾",
	},
	{
		id          = "prod_boost_1h",
		name        = "1-Hour Sugar Surge",
		description = "5× income for 60 minutes. Stackable up to ×3.",
		robuxPrice  = 49,
		productType = "devproduct",
		productId   = 99000004,   -- REPLACE
		icon        = "∂",
	},
	{
		id          = "prod_sugar_bag",
		name        = "Bag of Sugar",
		description = "Instantly grants 50,000 Starlight Sugar.",
		robuxPrice  = 79,
		productType = "devproduct",
		productId   = 99000005,   -- REPLACE
		icon        = "⨅",
	},
	{
		id          = "prod_sugar_chest",
		name        = "Sugar Chest",
		description = "Instantly grants 1,000,000 Starlight Sugar.",
		robuxPrice  = 299,
		productType = "devproduct",
		productId   = 99000006,   -- REPLACE
		icon        = "⨌",
	},
}

-- Daily reward tiers (indexed 1–7)
local DailyRewards = {
	{ amount = 50,    label = "50 Sugar",     icon = "⬡" },
	{ amount = 150,   label = "150 Sugar",    icon = "∰" },
	{ amount = 400,   label = "400 Sugar",    icon = "⨿" },
	{ amount = 1000,  label = "1K Sugar",     icon = "⨠" },
	{ amount = 3000,  label = "3K Sugar",     icon = "⨦" },
	{ amount = 8000,  label = "8K Sugar",     icon = "⧉" },
	{ amount = 25000, label = "25K Sugar",    icon = "⪾" },
}

-- Achievement definitions
local Achievements = {
	{ id = "first_bite",       name = "First Bite",         icon = "⬡", desc = "Bake your very first cookie.",          target = 1,       field = "lifetime" },
	{ id = "sugar_rush",       name = "Sugar Rush",          icon = "⨢", desc = "Bake 100 cookies total.",              target = 100,     field = "lifetime" },
	{ id = "bakery_novice",    name = "Bakery Novice",       icon = "ⅆ", desc = "Bake 1,000 cookies total.",            target = 1000,    field = "lifetime" },
	{ id = "sweet_tooth",      name = "Sweet Tooth",         icon = "⨂", desc = "Bake 25,000 cookies total.",           target = 25000,   field = "lifetime" },
	{ id = "master_baker",     name = "Master Baker",        icon = "⨰", desc = "Bake 1,000,000 cookies total.",       target = 1000000, field = "lifetime" },
	{ id = "first_upgrade",    name = "First Purchase",      icon = "⨝", desc = "Buy your first upgrade.",              target = 1,       field = "totalUpgrades" },
	{ id = "upgrade_addict",   name = "Upgrade Addict",      icon = "⨅", desc = "Own 25 upgrades total.",              target = 25,      field = "totalUpgrades" },
	{ id = "collector",        name = "Collector",           icon = "⨿", desc = "Own 5 different upgrade types.",      target = 5,       field = "uniqueUpgrades" },
	{ id = "click_frenzy",     name = "Click Frenzy",        icon = "∇", desc = "Click 200 times in one session.",     target = 200,     field = "sessionClicks" },
	{ id = "skin_curious",     name = "Skin Curious",        icon = "⨳", desc = "Unlock your first non-default skin.", target = 1,       field = "unlockedSkins" },
	{ id = "daily_habitue",    name = "Daily Habitué",       icon = "∂", desc = "Log in 3 days in a row.",             target = 3,       field = "loginStreak" },
	{ id = "devoted_baker",    name = "Devoted Baker",       icon = "∢", desc = "Log in 7 days in a row.",             target = 7,       field = "loginStreak" },
}

return {
	Products     = MonetizationConfig,
	DailyRewards = DailyRewards,
	Achievements = Achievements,
}
