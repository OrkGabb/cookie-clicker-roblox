--!strict
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Types              = require(ReplicatedStorage.Shared.Types)
local Constants          = require(ReplicatedStorage.Shared.Constants)
local UpgradeConfig      = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local SkinConfigModule   = require(ReplicatedStorage.Shared.Config.SkinConfig)
local Signal             = require(script.Parent.Parent.Util.Signal)
local CurrencyComp       = require(script.Parent.Parent.ECS.Components.Currency)
local UpgradeOwnerComp   = require(script.Parent.Parent.ECS.Components.UpgradeOwner)
local ClickerInputComp   = require(script.Parent.Parent.ECS.Components.ClickerInput)
local EffectRegistry     = require(script.Parent.Parent.ECS.Systems.EffectRegistry)

export type GameState = {
	Currency:     CurrencyComp.Currency,
	Upgrades:     UpgradeOwnerComp.UpgradeOwner,
	ClickerInput: ClickerInputComp.ClickerInput,

	-- Signals
	Changed:        Signal.Signal,
	StatsChanged:   Signal.Signal,
	SkinChanged:    Signal.Signal,
	SkinUnlocked:   Signal.Signal,
	AchievementUnlocked: Signal.Signal,

	-- Methods (IGameState interface)
	GetCurrency:      (self: GameState) -> number,
	GetLifetime:      (self: GameState) -> number,
	GetPerClick:      (self: GameState) -> number,
	GetPerSecond:     (self: GameState) -> number,
	GetUpgradeCount:  (self: GameState, id: string) -> number,
	GetActiveSkinId:  (self: GameState) -> string,
	HasSkin:          (self: GameState, id: string) -> boolean,
	AddCurrency:      (self: GameState, amount: number) -> (),
	DeductCurrency:   (self: GameState, amount: number) -> boolean,
	SetCurrency:      (self: GameState, amount: number) -> (),
	GetCupcake:       (self: GameState) -> number,
	SetCupcake:       (self: GameState, amount: number) -> (),
	DeductCupcake:    (self: GameState, amount: number) -> boolean,
	RecordPurchase:   (self: GameState, def: Types.UpgradeDefinition) -> (),
	SetActiveSkin:    (self: GameState, id: string) -> (),
	UnlockSkin:       (self: GameState, id: string) -> (),
	RecalculateStats: (self: GameState) -> (),
	LoadFromSave:     (self: GameState, save: Types.PlayerSaveData) -> (),
	BuildSaveData:    (self: GameState) -> Types.PlayerSaveData,
	Destroy:          (self: GameState) -> (),
}

local GameState = {}
GameState.__index = GameState

function GameState.new(): GameState
	local self = setmetatable({}, GameState) :: any

	self.Currency     = CurrencyComp.new()
	self.Upgrades     = UpgradeOwnerComp.new()
	self.ClickerInput = ClickerInputComp.new(Constants.CLICK_COOLDOWN)

	self._cupcake         = 0
	self._activeSkinId    = "classic"
	self._unlockedSkins   = { classic = true } :: { [string]: boolean }
	self._lastLoginTime   = 0
	self._lastClaimTimestamp = 0
	self._prestigeCount   = 0
	self._unlockedAchievements = {} :: { [string]: boolean }
	self._stats           = {
		totalClicks = 0,
		lifetimeCookies = 0,
		goldenCookiesCollected = 0,
		upgradesPurchasedTotal = 0,
		dailyStreak = 0,
	} :: Types.PlayerStats
	self._passMultiplier  = 1   -- from game passes
	self._settings        = table.clone(Constants.DEFAULT_SETTINGS) :: Types.ClientSettings

	-- Build upgrade def map for O(1) lookup
	self._defMap = {} :: { [string]: Types.UpgradeDefinition }
	for _, def in ipairs(UpgradeConfig) do
		self._defMap[def.id] = def
		self.Upgrades.counts[def.id] = 0
	end

	-- Signals
	self.Changed             = Signal.new()
	self.StatsChanged        = Signal.new()
	self.SkinChanged         = Signal.new()
	self.SkinUnlocked        = Signal.new()
	self.AchievementUnlocked = Signal.new()

	return self
end

-- ─── Currency ────────────────────────────────────────────────────────────────

function GameState:GetCurrency(): number
	return self.Currency.amount
end

function GameState:GetLifetimeCookies(): number
	return self._stats.lifetimeCookies
end

function GameState:GetPerClick(): number
	return math.max(1, self.Currency.perClick * self.Currency.clickMultiplier * self._passMultiplier)
end

function GameState:GetPerSecond(): number
	return self.Currency.perSecond * self.Currency.passiveMultiplier * self._passMultiplier
end

function GameState:AddCurrency(amount: number)
	self.Currency.amount          += amount
	self._stats.lifetimeCookies   += amount
	self.Changed:Fire()
	self:_checkMilestones()
end

function GameState:DeductCurrency(amount: number): boolean
	if self.Currency.amount < amount then return false end
	self.Currency.amount -= amount
	self.Changed:Fire()
	return true
end

-- Hard-set the balance to the server-authoritative value (reconcile). Direct set,
-- not a delta, so accumulated client/server prediction drift is squashed.
function GameState:SetCurrency(amount: number)
	self.Currency.amount = amount
	self.Changed:Fire()
end

-- ─── Cupcakes (CPK) ────────────────────────────────────────────────────────────

function GameState:GetCupcake(): number
	return self._cupcake
end

-- Reconcile to the server-authoritative cupcake balance (direct set).
function GameState:SetCupcake(amount: number)
	self._cupcake = amount
	self.Changed:Fire()
end

-- Optimistic deduct on a milestone purchase; server remains authoritative.
function GameState:DeductCupcake(amount: number): boolean
	if self._cupcake < amount then return false end
	self._cupcake -= amount
	self.Changed:Fire()
	return true
end

-- ─── Upgrades ────────────────────────────────────────────────────────────────

function GameState:GetUpgradeCount(id: string): number
	return self.Upgrades.counts[id] or 0
end

function GameState:RecordPurchase(def: Types.UpgradeDefinition)
	local prev = self.Upgrades.counts[def.id] or 0
	self.Upgrades.counts[def.id] = prev + 1
	self.Upgrades.totalOwned    += 1
	if prev == 0 then
		self.Upgrades.uniqueOwned += 1
	end
	self.Upgrades.sessionPurchases += 1
	self:RecalculateStats()
	self.Changed:Fire()
	self:_checkAchievements()
end

function GameState:RecalculateStats()
	local c = self.Currency
	local prevClick  = c.perClick
	local prevSecond = c.perSecond
	c.perClick  = Constants.STARTING_PER_CLICK
	c.perSecond = Constants.BASE_PASSIVE

	for id, count in pairs(self.Upgrades.counts) do
		if count > 0 then
			local def = self._defMap[id]
			if def then
				EffectRegistry.apply(def.kind, count, def.basePower, c)
			end
		end
	end

	if c.perClick ~= prevClick or c.perSecond ~= prevSecond then
		self.StatsChanged:Fire()
	end
end

-- ─── Skins ───────────────────────────────────────────────────────────────────

function GameState:GetActiveSkinId(): string
	return self._activeSkinId
end

function GameState:HasSkin(id: string): boolean
	return self._unlockedSkins[id] == true
end

function GameState:SetActiveSkin(id: string)
	if not self:HasSkin(id) then return end
	self._activeSkinId = id
	self.SkinChanged:Fire(id)
end

function GameState:UnlockSkin(id: string)
	if self._unlockedSkins[id] then return end
	self._unlockedSkins[id] = true
	self.SkinUnlocked:Fire(id)
end

-- ─── Passes / Multipliers ────────────────────────────────────────────────────

-- Server-authoritative gamepass cookie multiplier, pushed from the server (PlayerEffectsService
-- is the SSoT) so the client's optimistic prediction — the "+N" popup, running total, and CpS
-- readout — matches what the server actually credits. Monotonic (passes are only granted, never
-- revoked in-session) and change-guarded so a no-op reconcile tick doesn't fire the expensive
-- StatsChanged -> full Render path.
function GameState:ApplyPassMultiplier(mult: number)
	local newMult = math.max(self._passMultiplier, mult)
	if newMult == self._passMultiplier then return end
	self._passMultiplier = newMult
	self.StatsChanged:Fire()
end

-- ─── Milestone checks ────────────────────────────────────────────────────────

function GameState:_checkMilestones()
	local lifetime = self._stats.lifetimeCookies
	local skins = SkinConfigModule.Skins
	for _, skin in ipairs(skins) do
		if skin.unlockType == "milestone" and lifetime >= skin.unlockValue then
			self:UnlockSkin(skin.id)
		end
	end
end

function GameState:_checkAchievements()
	-- Session click achievements are checked from ClickSystem externally
end

-- ─── Persistence ─────────────────────────────────────────────────────────────

function GameState:LoadFromSave(save: Types.PlayerSaveData)
	self.Currency.amount          = save.currency
	self._cupcake                 = save.cupcake or 0

	for id, count in pairs(save.upgrades) do
		self.Upgrades.counts[id] = count
	end
	-- recalculate totals
	local total = 0
	local unique = 0
	for _, count in pairs(self.Upgrades.counts) do
		total += count
		if count > 0 then unique += 1 end
	end
	self.Upgrades.totalOwned  = total
	self.Upgrades.uniqueOwned = unique

	self._unlockedSkins = { classic = true }
	for _, skinId in ipairs(save.unlockedSkins) do
		self._unlockedSkins[skinId] = true
	end

	if self._unlockedSkins[save.activeSkinId] then
		self._activeSkinId = save.activeSkinId
	end

	self._lastLoginTime = save.lastLoginTime
	self._lastClaimTimestamp = save.lastClaimTimestamp or 0
	self._prestigeCount = save.prestigeCount
	self._unlockedAchievements = save.unlockedAchievements or {}

	if save.stats then
		self._stats = save.stats
	else
		self._stats = {
			totalClicks = 0,
			lifetimeCookies = save.lifetimeCookies or 0,
			goldenCookiesCollected = 0,
			upgradesPurchasedTotal = 0,
			dailyStreak = save.loginStreak or 0,
		}
	end

	if save.settings then
		self._settings = save.settings
	else
		self._settings = table.clone(Constants.DEFAULT_SETTINGS)
	end

	self:RecalculateStats()
	self:_checkMilestones()
	self.Changed:Fire()
	self.StatsChanged:Fire()
	self.SkinChanged:Fire(self._activeSkinId)
end

function GameState:BuildSaveData(): Types.PlayerSaveData
	local unlockedList: { string } = {}
	for id, _ in pairs(self._unlockedSkins) do
		table.insert(unlockedList, id)
	end
	return {
		version          = Constants.DATA_VERSION,
		currency         = self.Currency.amount,
		cupcake          = self._cupcake,
		-- Server-authoritative; the client never tracks it. BuildSaveData is currently unused
		-- (RequestSave is unwired), but it must stay schema-valid under --!strict.
		clickAccumulator = 0,
		quests           = { completed = {}, progress = {} },
		lifetimeCookies  = self._stats.lifetimeCookies,
		upgrades         = self.Upgrades.counts,
		unlockedSkins    = unlockedList,
		activeSkinId     = self._activeSkinId,
		lastLoginTime    = self._lastLoginTime,
		lastClaimTimestamp = self._lastClaimTimestamp,
		unlockedAchievements = self._unlockedAchievements,
		prestigeCount    = self._prestigeCount,
		ownedPasses      = {},
		settings         = self._settings,
		stats            = self._stats,
	}
end

-- ─── Stats & Achievements ──────────────────────────────────────────────────────

function GameState:GetStats(): Types.PlayerStats
	return self._stats
end

function GameState:HasAchievement(id: string): boolean
	return self._unlockedAchievements[id] == true
end

function GameState:GetLastClaimTimestamp(): number
	return self._lastClaimTimestamp
end

-- Used only for UI visual enablement. Not for logic gating.
function GameState:CanClaimDaily(): boolean
	local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)
	local delta = os.time() - self._lastClaimTimestamp
	if self._lastClaimTimestamp == 0 then
		return true
	end
	return delta >= Constants.DAILY_REWARD_COOLDOWN
end

function GameState:UpdateDailyState(newStreak: number, newTimestamp: number)
	self._stats.dailyStreak = newStreak
	self._lastClaimTimestamp = newTimestamp
	self.StatsChanged:Fire()
end

-- ─── Settings ────────────────────────────────────────────────────────────────

function GameState:GetSettings(): Types.ClientSettings
	return self._settings
end

function GameState:UpdateSettings(newSettings: Types.ClientSettings)
	self._settings = table.clone(newSettings)
	self.Changed:Fire()
end

function GameState:Destroy()
	self.Changed:Destroy()
	self.StatsChanged:Destroy()
	self.SkinChanged:Destroy()
	self.SkinUnlocked:Destroy()
	self.AchievementUnlocked:Destroy()
end

return GameState
