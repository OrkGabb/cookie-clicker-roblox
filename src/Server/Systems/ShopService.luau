--!strict
-- Server-authoritative shop. Owns the single MarketplaceService.ProcessReceipt callback
-- (idempotent, persisted per-profile) and grants gamepass perks via
-- PromptGamePassPurchaseFinished. Rewards come from the shared ShopConfig SSoT — never
-- trust the client for what/whether to grant.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)

local ShopService = {}

-- Credits a dev-product reward to the player's profile. Returns false on unknown product.
local function applyDevProduct(player: Player, product: ShopConfig.ShopProduct): boolean
	if product.currency == "cookie" and product.amount then
		DataService.AddCurrency(player, product.amount)
		return true
	elseif product.currency == "cupcake" and product.amount then
		DataService.AddCupcake(player, product.amount)
		return true
	end
	return false
end

-- ProcessReceipt: called by Roblox after a dev-product purchase succeeds. Must be
-- idempotent — Roblox can call it more than once for the same PurchaseId until we
-- confirm PurchaseGranted, so we persist processed PurchaseIds in the profile.
function ShopService.ProcessReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left; let Roblox retry when they're back (or it expires).
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.GetProfileData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receiptInfo.PurchaseId)

	-- Already credited (idempotency): acknowledge without re-granting.
	if data.processedReceipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = ShopConfig.RewardById[receiptInfo.ProductId]
	if not product or product.productType ~= "devproduct" then
		-- Unknown product: acknowledge so Roblox stops retrying (no reward to give).
		warn("[ShopService] Unknown dev product: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if not applyDevProduct(player, product) then
		-- Misconfigured reward: let Roblox retry rather than eat the purchase.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Mark processed only AFTER a successful grant, then notify the client so the
	-- balance updates immediately instead of waiting for the next reconcile tick.
	data.processedReceipts[purchaseId] = true

	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	;(Remotes :: any).ShopPurchaseGranted:FireClient(player, product.productId)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Grants a gamepass perk by persisting its productId in ownedPasses (the existing schema
-- field MonetizationService.CheckGamepass reads). No-op if already owned.
function ShopService.GrantGamepass(player: Player, gamePassId: number)
	local data = DataService.GetProfileData(player)
	if not data then return end

	local product = ShopConfig.RewardById[gamePassId]
	if not product or product.productType ~= "gamepass" then return end

	local idStr = tostring(gamePassId)
	for _, owned in ipairs(data.ownedPasses) do
		if owned == idStr then return end -- already owned, don't duplicate
	end

	table.insert(data.ownedPasses, idStr)

	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	;(Remotes :: any).ShopPurchaseGranted:FireClient(player, gamePassId)
end

function ShopService.Init()
	-- Single owner of the receipt callback (see MonetizationService.Init note).
	MarketplaceService.ProcessReceipt = ShopService.ProcessReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, gamePassId: number, wasPurchased: boolean)
			if wasPurchased then
				ShopService.GrantGamepass(player, gamePassId)
			end
		end
	)
end

return ShopService
