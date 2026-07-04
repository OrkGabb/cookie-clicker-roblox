--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Declare)
local UpgradeButton = require(script.Parent.Components.UpgradeButton)
local ClickerArea = require(script.Parent.Components.ClickerArea)
local Sidebar = require(script.Parent.Components.Sidebar)

local Types = require(ReplicatedStorage.Shared.Types)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local EconomyMath = require(ReplicatedStorage.Shared.Util.EconomyMath)

local function MainGui(props: {
	currency: number,
	cupcake: number,
	perSecond: number,
	activeSkinDef: Types.SkinDefinition,
	upgrades: {Types.UpgradeDefinition},
	upgradeCounts: {[string]: number},
	onClickTreat: () -> (),
	onBuyUpgrade: (id: string) -> (),
	onShop: (() -> ())?,
	onSettings: (() -> ())?,
	onDailyReward: (() -> ())?,
	onQuests: (() -> ())?
}): Instance

	local shopChildren: {Instance} = {
		Declare.UIListLayout({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Theme.Padding.Standard,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Declare.UIPadding({
			PaddingTop = Theme.Padding.Standard,
			PaddingBottom = Theme.Padding.Standard,
		}),
		Declare.TextLabel({
			Name = "UpgradesHeader",
			Size = UDim2.new(1, -20, 0, 50),
			BackgroundTransparency = 1,
			Text = "Upgrades",
			Font = Theme.Fonts.Display,
			TextSize = 32,
			TextColor3 = Theme.Colors.TextPrimary,
			LayoutOrder = -1,
		}),
	}
	
	for _, def in ipairs(props.upgrades) do
		local count = props.upgradeCounts[def.id] or 0
		local cost = EconomyMath.ComputeUpgradeCost(def, count)
		local maxed = def.maxStacks ~= nil and count >= def.maxStacks
		local cupcakeCost = EconomyMath.ComputeMilestoneCupcakeCost(def.id, count + 1)
		local canAffordCupcake = cupcakeCost == 0 or props.cupcake >= cupcakeCost
		local canAfford = props.currency >= cost and canAffordCupcake and not maxed
		table.insert(shopChildren, UpgradeButton({
			def = def,
			count = count,
			cost = cost,
			canAfford = canAfford,
			maxed = maxed,
			cupcakeCost = cupcakeCost,
			onClick = function() props.onBuyUpgrade(def.id) end
		}))
	end

	return Declare.New("ScreenGui")({
		Name = "MainGui",
		IgnoreGuiInset = true,
		ClipToDeviceSafeArea = true,
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		Children = {
			Declare.Frame({
				Name = "Background",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.Colors.BackgroundCream,
			}),
			
			Declare.Frame({
				Name = "TopBar",
				Size = UDim2.new(1, 0, 0.1, 0),
				BackgroundColor3 = Theme.Colors.HeaderPink,
				BorderSizePixel = 0,
				Children = {
					Declare.UISizeConstraint({ MaxSize = Vector2.new(9999, 80), MinSize = Vector2.new(0, 50) }),
					Declare.UIStroke({
						Color = Theme.Colors.Cocoa,
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					Declare.Frame({
						Name = "CurrencyContainer",
						Size = UDim2.fromScale(1, 0.6),
						BackgroundTransparency = 1,
						Children = {
							Declare.UIListLayout({
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = Theme.Padding.Small,
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							Declare.TextLabel({
								Name = "CurrencyDisplay",
								Size = UDim2.fromScale(0, 1),
								AutomaticSize = Enum.AutomaticSize.X,
								BackgroundTransparency = 1,
								Text = NumberFormat.Format(props.currency),
								Font = Theme.Fonts.Display,
								TextScaled = false,
								TextSize = 36,
								TextColor3 = Theme.Colors.TextPrimary,
							}),
							Declare.New("ImageLabel")({
								Name = "CurrencyIcon",
								Size = UDim2.fromScale(0.8, 0.8),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								BackgroundTransparency = 1,
								Image = AssetIds.CookieMini,
								ScaleType = Enum.ScaleType.Fit,
							})
						}
					}),
					Declare.TextLabel({
						Name = "PassiveDisplay",
						Size = UDim2.fromScale(1, 0.4),
						Position = UDim2.fromScale(0, 0.6),
						BackgroundTransparency = 1,
						Text = "+" .. NumberFormat.Rate(props.perSecond, "/s"),
						Font = Theme.Fonts.Body,
						TextScaled = true,
						TextColor3 = Theme.Colors.TextSecondary,
						Children = { Declare.UITextSizeConstraint({ MaxTextSize = 20 }) }
					}),
					Declare.Frame({
						Name = "CupcakeContainer",
						Size = UDim2.fromScale(0.25, 0.55),
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -15, 0.5, 0),
						BackgroundTransparency = 1,
						Children = {
							Declare.UIListLayout({
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Right,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = Theme.Padding.Small,
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							Declare.TextLabel({
								Name = "CupcakeDisplay",
								Size = UDim2.fromScale(0, 1),
								AutomaticSize = Enum.AutomaticSize.X,
								BackgroundTransparency = 1,
								LayoutOrder = 1,
								Text = NumberFormat.Format(props.cupcake),
								Font = Theme.Fonts.Display,
								TextScaled = false,
								TextSize = 28,
								TextColor3 = Theme.Colors.TextPrimary,
							}),
							Declare.New("ImageLabel")({
								Name = "CupcakeIcon",
								Size = UDim2.fromScale(0.8, 0.8),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								BackgroundTransparency = 1,
								LayoutOrder = 2,
								Image = AssetIds.Cupcake,
								ScaleType = Enum.ScaleType.Fit,
							})
						}
					})
				}
			}),
			
			Sidebar({
				onShop = props.onShop or function() end,
				onSettings = props.onSettings or function() end,
				onDailyReward = props.onDailyReward or function() end,
				onQuests = props.onQuests or function() end,
			}),
			
			Declare.ScrollingFrame({
				Name = "ShopPanel",
				Size = UDim2.new(0.3, 0, 0.85, 0),
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -10, 1, -10),
				BackgroundColor3 = Theme.Colors.PanelLavender,
				ScrollBarThickness = 6,
				CanvasSize = UDim2.fromScale(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Children = {
					Declare.UISizeConstraint({ MaxSize = Vector2.new(400, 9999), MinSize = Vector2.new(250, 0) }),
					Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
					Declare.UIStroke({
						Color = Theme.Colors.Cocoa,
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					table.unpack(shopChildren)
				}
			}),
			
			Declare.Frame({
				Name = "ClickerConstraint",
				Size = UDim2.new(0.62, 0, 1, 0),
				Position = UDim2.new(0.08, 0, 0, 0),
				BackgroundTransparency = 1,
				Children = {
					ClickerArea({
						skinDef = props.activeSkinDef,
						onClick = props.onClickTreat
					})
				}
			})
		}
	})
end

return MainGui
