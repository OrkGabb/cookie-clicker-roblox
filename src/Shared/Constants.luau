--!strict
local Constants = {
	CURRENCY_NAME = "Starlight Sugar",
	CURRENCY_SYMBOL = "⧉",
	CLICK_COOLDOWN = 0.05,
	STARTING_CURRENCY = 0,
	STARTING_PER_CLICK = 1,
	BASE_PASSIVE = 0,
	AUTO_SAVE_INTERVAL = 60,
	DATA_VERSION = 1,
	-- layout
	SHOP_WIDTH = 320,
	LEFT_PANEL_WIDTH = 64,
	TOP_BAR_HEIGHT = 84,
	TILE_SIZE = 96,
	-- animation
	FLOAT_ORBIT_X = 165,
	FLOAT_ORBIT_Y = 72,
	FLOAT_SPEED = 0.45,
	FLOAT_COUNT = 7,
	DEFAULT_SETTINGS = {
		masterVolume = 100,
		musicVolume = 60, -- music defaults to 60% (SSoT for new saves + Reset)
		sfxVolume = 100,
		performanceMode = false,
		notifications = true,
		-- Auto-Clicker gamepass on/off. Defaults ON so the perk works immediately on
		-- first grant (matches the Shop's "no clicking required"). Only owners ever see
		-- the toggle; for non-owners the flag is inert (no auto-click loop exists).
		autoClickerEnabled = true,
	},
	DAILY_REWARD_COOLDOWN = 86400,
	DAILY_REWARD_GRACE_PERIOD = 172800,
	-- Passive income (server-authoritative accrual + client reconcile)
	PASSIVE_TICK_INTERVAL = 1,        -- server accrual cadence, seconds
	BALANCE_RECONCILE_INTERVAL = 5,   -- client resync-to-authoritative cadence, seconds
	-- Fast-buy (hold upgrade button to repeat-purchase)
	FAST_BUY_HOLD_DELAY = 0.35, -- delay before rapid-fire kicks in
	FAST_BUY_CADENCE = 0.2,     -- interval between rapid purchases
	FAST_BUY_CAP = 100,         -- safety cap per hold
}
return Constants
