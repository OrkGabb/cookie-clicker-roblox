--!strict
local Types = {}

export type UpgradeKind = string

export type UpgradeDefinition = {
	id: string,
	name: string,
	statLabel: string,
	kind: UpgradeKind,
	baseCost: number,
	costGrowth: number,
	basePower: number,
	icon: string,
	maxStacks: number?,
}

export type SkinDefinition = {
	id: string,
	name: string,
	description: string,
	unlockType: "default" | "milestone" | "robux" | "achievement",
	unlockValue: number,
	cookieIcon: string,
	miniIcon: string,
	gradientA: Color3,
	gradientB: Color3,
	borderColor: Color3,
	accentColor: Color3,
}

export type MonetizationProduct = {
	id: string,
	name: string,
	description: string,
	robuxPrice: number,
	productType: "gamepass" | "devproduct",
	productId: number,
	icon: string,
}

export type PlayerStats = {
	totalClicks: number,
	lifetimeCookies: number,
	goldenCookiesCollected: number,
	upgradesPurchasedTotal: number,
	upgradesPurchasedClicker: number,
	upgradesPurchasedPassive: number,
	dailyStreak: number,
}

export type AchievementDefinition = {
	id: string,
	title: string,
	description: string,
	icon: string,
	statKey: string,
	threshold: number,
	rewardType: "Currency" | "Cosmetic",
	rewardAmount: number,
	rewardSkinId: string?,
}

export type ClientSettings = {
	masterVolume: number,
	musicVolume: number,
	sfxVolume: number,
	performanceMode: boolean,
	notifications: boolean,
	autoClickerEnabled: boolean,
}

export type QuestState = {
	completed: { [string]: boolean },
	progress: { [string]: number },
}

export type PlayerSaveData = {
	version: number,
	currency: number,
	cupcake: number,          -- spendable cupcake (CPK) balance
	clickAccumulator: number, -- server-side manual-click tally toward the next cupcake; mints one cupcake per CLICKS_PER_CUPCAKE and carries the remainder
	quests: QuestState,
	lifetimeCookies: number,
	upgrades: {[string]: number},
	unlockedSkins: {string},
	activeSkinId: string,
	lastLoginTime: number,
	lastClaimTimestamp: number,
	unlockedAchievements: {[string]: boolean},
	prestigeCount: number,
	ownedPasses: {string},
	processedReceipts: {[string]: boolean}, -- Roblox PurchaseId set; dev-product idempotency
	settings: ClientSettings,
	stats: PlayerStats,
}

export type IGameState = {
	GetCurrency: (self: IGameState) -> number,
	GetLifetime: (self: IGameState) -> number,
	GetPerClick: (self: IGameState) -> number,
	GetPerSecond: (self: IGameState) -> number,
	GetUpgradeCount: (self: IGameState, id: string) -> number,
	GetActiveSkinId: (self: IGameState) -> string,
	HasSkin: (self: IGameState, id: string) -> boolean,
	AddCurrency: (self: IGameState, amount: number) -> (),
	DeductCurrency: (self: IGameState, amount: number) -> boolean,
	RecordPurchase: (self: IGameState, def: UpgradeDefinition) -> (),
	SetActiveSkin: (self: IGameState, id: string) -> (),
	UnlockSkin: (self: IGameState, id: string) -> (),
	ClickerInput: { lastClick: number, cooldown: number },
	GetSettings: (self: IGameState) -> ClientSettings,
	UpdateSettings: (self: IGameState, newSettings: ClientSettings) -> (),
	GetStats: (self: IGameState) -> PlayerStats,
	HasAchievement: (self: IGameState, id: string) -> boolean,
}

return Types
