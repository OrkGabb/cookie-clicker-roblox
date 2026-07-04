--!strict
-- Single source of truth for gamepass ownership -> gameplay effect resolution.
-- Economy systems (ValidationSystem, ServerPassiveSystem) call into this service for
-- multipliers and never check MarketplaceService ownership directly, so adding a 5th
-- gamepass only touches ShopConfig + this file (OCP). Ownership is resolved once on
-- join (UserOwnsGamePassAsync is the authoritative real-money source) and refreshed
-- on in-session purchase via PromptGamePassPurchaseFinished — never polled per frame.
--
-- @author OrkGabb
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PlayerEffectsService = {}

-- The gamepass subset of ShopConfig, snapshotted once (effects are config-driven).
local gamepasses: { ShopConfig.ShopProduct } = {}
for _, product in ipairs(ShopConfig.Products) do
	if product.productType == "gamepass" then
		table.insert(gamepasses, product)
	end
end

-- Per-player ownership cache: { [Player] = { [productId] = true } }. A nil entry means
-- ownership has not been resolved yet (treated as "owns nothing" -> all multipliers 1.0).
local owned: { [Player]: { [number]: boolean } } = {}

-- Per-player auto-clicker run flag. Setting false stops the loop on the next tick.
local autoClickerActive: { [Player]: boolean } = {}

-- Resolves and caches ownership of every gamepass for one player. Safe to call again
-- to refresh (e.g. after a purchase). Each lookup is wrapped — a MarketplaceService
-- outage must not block the player from earning at baseline rates.
local function resolveOwnership(player: Player)
	local set: { [number]: boolean } = owned[player] or {}
	owned[player] = set
	for _, product in ipairs(gamepasses) do
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, product.productId)
		end)
		if ok then
			set[product.productId] = result == true
		end
	end
end

-- Returns the stacked multiplier for a currency across all owned gamepasses. Stacks
-- multiplicatively under the current flat-multiplier design: e.g. owning Cookie 2x + VIP
-- (also ×2) yields 2 * 2 = 4x cookies. Defaults to 1.0 for players who own nothing, so
-- non-owners are completely unaffected.
function PlayerEffectsService:GetMultiplier(player: Player, currencyType: "Cookie" | "Cupcake"): number
	local set = owned[player]
	if not set then return 1.0 end

	local mult = 1.0
	for _, product in ipairs(gamepasses) do
		if set[product.productId] then
			local m = if currencyType == "Cookie" then product.cookieMultiplier else product.cupcakeMultiplier
			if m then
				mult *= m
			end
		end
	end
	return mult
end

function PlayerEffectsService:HasAutoClicker(player: Player): boolean
	local set = owned[player]
	if not set then return false end
	for _, product in ipairs(gamepasses) do
		if set[product.productId] and product.grantsAutoClicker then
			return true
		end
	end
	return false
end

-- Auto-Clicker cadence: 4 ticks/second. Each tick is still ONE ProcessClicks(player, 1)
-- + one AutoClickTick, so the visual feedback (popup/squish/sound) stays 1:1 with the
-- credited amount — we run 4x more often rather than crediting 4x per tick. Set above a
-- free player's sustainable manual rate so the R$240 gamepass clearly outperforms.
local AUTO_CLICK_INTERVAL = 1 / 4

-- Drives the Auto-Clicker gamepass: ticks at AUTO_CLICK_INTERVAL, running the exact same
-- server-side click pipeline a manual click uses (ValidationSystem.ProcessClicks) so it
-- inherits the same validation, CPK accrual, and multipliers — no parallel earning path.
local function startAutoClicker(player: Player)
	if autoClickerActive[player] then return end
	autoClickerActive[player] = true
	task.spawn(function()
		-- Lazy require avoids a load-time cycle (ValidationSystem -> PlayerEffectsService).
		local ValidationSystem = require(script.Parent.ValidationSystem)
		local DataService = require(script.Parent.Parent.Services.DataService)
		local autoClickTick = (Remotes :: any).AutoClickTick :: RemoteEvent
		while autoClickerActive[player] and player:IsDescendantOf(Players) do
			task.wait(AUTO_CLICK_INTERVAL)
			if not autoClickerActive[player] or not player:IsDescendantOf(Players) then break end
			-- Per-player on/off toggle (Settings panel). The loop stays alive while paused
			-- and simply skips the tick, so toggling resumes within one interval (~0.25s)
			-- with no re-spawn (~0.25s). nil/absent flag is treated as ON (default true on first grant).
			local data = DataService.GetProfileData(player)
			if data and data.settings.autoClickerEnabled ~= false then
				ValidationSystem.ProcessClicks(player, 1)
				-- Auto-clicks are entirely server-side, so the client gets no trigger for
				-- the manual-click VFX. Ping the owner to replay the exact same "+N" popup,
				-- cookie squish, and click sound a manual click produces (already gated to
				-- 1/s by this loop, so no extra throttling needed).
				autoClickTick:FireClient(player)
			end
		end
		autoClickerActive[player] = nil
	end)
end

local function onPlayerAdded(player: Player)
	resolveOwnership(player)
	if PlayerEffectsService:HasAutoClicker(player) then
		startAutoClicker(player)
	end
end

function PlayerEffectsService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		autoClickerActive[player] = false
		owned[player] = nil
	end)
	-- Players already present when the server boots (Studio Play solo, late require).
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	-- Refresh the single purchased pass and kick off the auto-clicker if that's what
	-- they bought, so the effect is live immediately without a rejoin.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, _gamePassId: number, wasPurchased: boolean)
			if not wasPurchased then return end
			resolveOwnership(player)
			if PlayerEffectsService:HasAutoClicker(player) then
				startAutoClicker(player)
			end
		end
	)
end

return PlayerEffectsService
