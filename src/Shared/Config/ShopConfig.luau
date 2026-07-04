--!strict
-- SSoT for the Robux shop (gamepasses + dev products). Prices are intentionally NOT
-- stored here — they are fetched live from MarketplaceService:GetProductInfo so the
-- panel never drifts from the real Roblox price. Server grant logic reads RewardById.
local AssetIds = require(script.Parent.Parent.AssetIds)

export type ShopProduct = {
	key: string,
	name: string,
	description: string,
	icon: string,
	productId: number,
	productType: "gamepass" | "devproduct",
	-- Grant spec (server-authoritative). Gamepasses set a persistent perk flag;
	-- dev products credit a currency amount.
	effect: string?,                       -- gamepass perk key (stored in ownedPasses)
	currency: ("cookie" | "cupcake")?,     -- dev product target balance
	amount: number?,                       -- dev product amount
	-- Gamepass effect data (SSoT). PlayerEffectsService reads these to resolve
	-- ownership -> gameplay effect, so adding a 5th pass only touches this config.
	-- Multipliers stack multiplicatively across owned passes (default 1.0 each).
	cookieMultiplier: number?,             -- ×N on Cookie gain (clicks + passive)
	cupcakeMultiplier: number?,            -- ×N on Cupcake (CPK) gain
	grantsAutoClicker: boolean?,           -- simulates manual clicks (4 ticks/second)
}

local Products: { ShopProduct } = {
	-- ── Gamepasses (permanent, one-time) ──────────────────────────────────────
	{
		key = "pass_cookie_2x", name = "2x Cookie Power",
		description = "Permanently double all cookies earned from clicks and passive income.",
		icon = AssetIds.CookieMain, productId = 1890766383,
		productType = "gamepass", effect = "cookie_2x",
		cookieMultiplier = 2,
	},
	{
		key = "pass_cupcake_2x", name = "2x Cupcake Power",
		description = "Permanently double all cupcakes you earn.",
		icon = AssetIds.Cupcake, productId = 1890790381,
		productType = "gamepass", effect = "cupcake_2x",
		cupcakeMultiplier = 2,
	},
	{
		key = "pass_autoclicker", name = "Auto-Clicker",
		description = "Automatically bakes cookies for you — no clicking required.",
		icon = AssetIds.CookieMini, productId = 1893196314,
		productType = "gamepass", effect = "autoclicker",
		grantsAutoClicker = true,
	},
	{
		key = "pass_vip_baker", name = "VIP Baker",
		description = "Permanently double both your cookies AND cupcakes (×2 each).",
		icon = AssetIds.Golden_Cookie, productId = 1891030362,
		productType = "gamepass", effect = "vip_baker",
		cookieMultiplier = 2, cupcakeMultiplier = 2,
	},

	-- ── Dev products (consumable, repeatable) ─────────────────────────────────
	{
		key = "prod_cookie_1k", name = "1K Cookie Pack",
		description = "Instantly receive 1,000 cookies.",
		icon = AssetIds.CookieMini, productId = 3606287222,
		productType = "devproduct", currency = "cookie", amount = 1000,
	},
	{
		key = "prod_cookie_10k", name = "10K Cookie Pack",
		description = "Instantly receive 10,000 cookies.",
		icon = AssetIds.CookieMini, productId = 3606287330,
		productType = "devproduct", currency = "cookie", amount = 10000,
	},
	{
		key = "prod_cookie_100k", name = "100K Cookie Pack",
		description = "Instantly receive 100,000 cookies.",
		icon = AssetIds.CookieMini, productId = 3606287474,
		productType = "devproduct", currency = "cookie", amount = 100000,
	},
	{
		key = "prod_cupcake_25", name = "25 Cupcake Pack",
		description = "Instantly receive 25 cupcakes.",
		icon = AssetIds.Cupcake, productId = 3606287589,
		productType = "devproduct", currency = "cupcake", amount = 25,
	},
	{
		key = "prod_cupcake_100", name = "100 Cupcake Pack",
		description = "Instantly receive 100 cupcakes.",
		icon = AssetIds.Cupcake, productId = 3606287870,
		productType = "devproduct", currency = "cupcake", amount = 100,
	},
}

-- productId -> product, for O(1) server grant lookup.
local RewardById: { [number]: ShopProduct } = {}
for _, p in ipairs(Products) do
	RewardById[p.productId] = p
end

return {
	Products = Products,
	RewardById = RewardById,
}
