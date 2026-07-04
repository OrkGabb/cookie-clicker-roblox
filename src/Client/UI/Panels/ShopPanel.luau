--!strict
-- Robux shop. Lists every ShopConfig product with a live price pulled from
-- MarketplaceService (never hardcoded). Buy buttons fire the native purchase prompt;
-- the server (ShopService) is the sole authority that actually grants rewards.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Declare = require(script.Parent.Parent.Declare)
local WindowPanel = require(script.Parent.Parent.Components.WindowPanel)
local Button = require(script.Parent.Parent.Components.Button)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local SoundController = require(ReplicatedStorage.Shared.Util.SoundController)

local LocalPlayer = Players.LocalPlayer

-- Live price lookup. Yields, so callers run it inside task.spawn. Returns a display string.
local function fetchPriceText(product: ShopConfig.ShopProduct): string
	local infoType = if product.productType == "gamepass"
		then Enum.InfoType.GamePass
		else Enum.InfoType.Product
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(product.productId, infoType)
	end)
	if ok and info and info.PriceInRobux then
		return "R$ " .. tostring(info.PriceInRobux)
	end
	return "R$ ?"
end

local function promptPurchase(product: ShopConfig.ShopProduct)
	if product.productType == "gamepass" then
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, product.productId)
	else
		MarketplaceService:PromptProductPurchase(LocalPlayer, product.productId)
	end
end

local function productRow(product: ShopConfig.ShopProduct, layoutOrder: number): Instance
	local priceLabel = Declare.TextLabel({
		Name = "Price",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = "R$ …",
		Font = Theme.Fonts.Body,
		TextSize = 16,
		TextColor3 = Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Async live price (does not block panel construction).
	task.spawn(function()
		local text = fetchPriceText(product)
		priceLabel.Text = text
	end)

	-- Shared CTA widget (same native button Daily Rewards' Claim uses). FlexMode
	-- None keeps its fixed 110px width inside the horizontal row layout.
	local buyButton = Button({
		size = UDim2.new(0, 110, 1, -20),
		text = "Buy",
		flexMode = Enum.UIFlexMode.None,
		onClick = function()
			-- Immediate audio feedback on buy. Routed through SoundController (SFX
			-- group), so the Master/SFX volume settings scale it. One-shot per click.
			SoundController.Play("Purchase")
			promptPurchase(product)
		end,
	})

	-- Gamepasses can already be owned: reflect that and disable re-purchase.
	if product.productType == "gamepass" then
		task.spawn(function()
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, product.productId)
			end)
			if ok and owns then
				buyButton.Text = "Owned"
				buyButton.AutoButtonColor = false
				buyButton.BackgroundColor3 = Theme.Colors.Maxed
				buyButton.Active = false
			end
		end)
	end

	return Declare.Frame({
		Name = "ShopItem_" .. product.key,
		Size = UDim2.new(1, -16, 0, 90),
		BackgroundColor3 = Theme.Colors.BackgroundCream,
		LayoutOrder = layoutOrder,
		Children = {
			Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
			Declare.UIStroke({ Color = Theme.Colors.Cocoa, Thickness = 2 }),
			Declare.UIPadding({
				PaddingTop = Theme.Padding.Small,
				PaddingBottom = Theme.Padding.Small,
				PaddingLeft = Theme.Padding.Standard,
				PaddingRight = Theme.Padding.Standard,
			}),
			Declare.UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = Theme.Padding.Standard,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Declare.New("ImageLabel")({
				Size = UDim2.new(0, 64, 0, 64),
				BackgroundTransparency = 1,
				Image = product.icon,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				Children = {
					Declare.UIFlexItem({ FlexMode = Enum.UIFlexMode.None }),
				},
			}),
			Declare.Frame({
				Name = "Info",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Children = {
					Declare.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
					Declare.UIListLayout({
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 2),
					}),
					Declare.TextLabel({
						Size = UDim2.new(1, 0, 0, 22),
						BackgroundTransparency = 1,
						Text = product.name,
						Font = Theme.Fonts.Display,
						TextSize = 20,
						TextColor3 = Theme.Colors.TextPrimary,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 1,
					}),
					Declare.TextLabel({
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						Text = product.description,
						Font = Theme.Fonts.Body,
						TextSize = 14,
						TextWrapped = true,
						TextColor3 = Theme.Colors.TextSecondary,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 2,
					}),
					priceLabel,
				},
			}),
			buyButton,
		},
	})
end

local function ShopPanel(props: { onClose: () -> () }): Instance
	local rows: { Instance } = {
		Declare.UIListLayout({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Theme.Padding.Standard,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Declare.UIPadding({
			PaddingTop = Theme.Padding.Standard,
			PaddingBottom = Theme.Padding.Standard,
		}),
	}

	for i, product in ipairs(ShopConfig.Products) do
		table.insert(rows, productRow(product, i))
	end

	local list = Declare.ScrollingFrame({
		Name = "RobuxShopList",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Children = rows,
	})

	return WindowPanel({
		title = "Shop",
		children = { list },
		onClose = props.onClose,
	})
end

return ShopPanel
