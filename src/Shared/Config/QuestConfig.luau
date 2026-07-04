--!strict
-- SSoT for quests (7c). Reward is CPK (cupcakes). `kind` selects how QuestService
-- computes live progress from authoritative player data; `target` is the goal.
-- Reward tiers (doubled per Gabriel): easy = 2, medium = 4, hard = 10.
export type QuestKind = "totalClicks" | "uniqueUpgrades" | "peakCurrency" | "passiveTicks"

export type QuestDefinition = {
	id: string,
	name: string,
	description: string,
	tier: "easy" | "medium" | "hard",
	kind: QuestKind,
	target: number,
	reward: number, -- cupcakes (CPK)
}

local QuestConfig: { QuestDefinition } = {
	{
		id = "quest_click_100",
		name = "Click Enthusiast",
		description = "Click 100 times",
		tier = "easy",
		kind = "totalClicks",
		target = 100,
		reward = 2,
	},
	{
		id = "quest_buy_5_upgrades",
		name = "Upgrade Spree",
		description = "Own 5 different upgrades",
		tier = "medium",
		kind = "uniqueUpgrades",
		target = 5,
		reward = 4,
	},
	{
		id = "quest_reach_10k_cookies",
		name = "Cookie Baron",
		description = "Reach 10,000 cookies",
		tier = "hard",
		kind = "peakCurrency",
		target = 10000,
		reward = 10,
	},
	{
		id = "quest_reach_100k_cookies",
		name = "Cookie Magnate",
		description = "Reach 100,000 cookies",
		tier = "hard",
		kind = "peakCurrency",
		target = 100000,
		reward = 10,
	},
	{
		id = "quest_passive_run_60s",
		name = "AFK Master",
		description = "Run passive income for 60s",
		tier = "medium",
		kind = "passiveTicks",
		target = 60,
		reward = 4,
	},
}

return QuestConfig
