--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local Constants = require(ReplicatedStorage.Shared.Constants)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local Types = require(ReplicatedStorage.Shared.Types)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

local HOVER_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function UpgradeButton(props: {
	def: Types.UpgradeDefinition,
	count: number,
	cost: number,
	canAfford: boolean,
	maxed: boolean?,
	cupcakeCost: number?, -- cupcake cost of the NEXT purchase (0/nil = none)
	onClick: () -> ()
}): Instance

	local cupcakeCost = props.cupcakeCost or 0

	local btn = Declare.New("TextButton")({
		Name = "Upgrade_" .. props.def.id,
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundColor3 = props.canAfford and Theme.Colors.Cream or Theme.Colors.BackgroundCream,
		Text = "",
		AutoButtonColor = false, -- themed states are driven manually (Item 5b)
		Children = {
			Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
			Declare.UIStroke({
				Color = Theme.Colors.Cocoa,
				Thickness = 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Declare.Frame({
				Name = "IconContainer",
				Size = UDim2.new(0, 60, 1, -10),
				Position = UDim2.fromOffset(5, 5),
				BackgroundColor3 = Theme.Colors.Blush,
				Children = {
					Declare.UICorner({ CornerRadius = Theme.Corners.Small }),
					Declare.New("ImageLabel")({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Image = props.def.icon,
						ScaleType = Enum.ScaleType.Fit,
					})
				}
			}),
			Declare.Frame({
				Name = "InfoContainer",
				Size = UDim2.new(1, -80, 1, -10),
				Position = UDim2.fromOffset(75, 5),
				BackgroundTransparency = 1,
				Children = {
					Declare.UIListLayout({
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = Theme.Padding.Small,
					}),
					Declare.Frame({
						Name = "TitleContainer",
						Size = UDim2.new(1, 0, 0.5, 0),
						BackgroundTransparency = 1,
						Children = {
							Declare.TextLabel({
								Name = "Title",
								Size = UDim2.new(0.7, 0, 1, 0),
								BackgroundTransparency = 1,
								Text = props.def.name .. " (x" .. props.count .. ")",
								Font = Theme.Fonts.Display,
								TextScaled = true,
								TextColor3 = props.canAfford and Theme.Colors.TextPrimary or Theme.Colors.TextMuted,
								TextXAlignment = Enum.TextXAlignment.Left,
								Children = { Declare.UITextSizeConstraint({ MaxTextSize = 18 }) }
							}),
							Declare.TextLabel({
								Name = "Effect",
								Size = UDim2.new(0.3, 0, 1, 0),
								Position = UDim2.fromScale(0.7, 0),
								BackgroundTransparency = 1,
								Text = "+" .. NumberFormat.Format(props.def.basePower) .. props.def.statLabel,
								Font = Theme.Fonts.Body,
								TextScaled = true,
								TextColor3 = props.canAfford and Theme.Colors.TextPrimary or Theme.Colors.TextMuted,
								TextXAlignment = Enum.TextXAlignment.Right,
								Children = { Declare.UITextSizeConstraint({ MaxTextSize = 16 }) }
							}),
						}
					}),
					Declare.Frame({
						Name = "CostContainer",
						Size = UDim2.new(1, 0, 0.5, 0),
						BackgroundTransparency = 1,
						Children = {
							Declare.UIListLayout({
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = Theme.Padding.Small,
							}),
							Declare.TextLabel({
								Name = "CostText",
								Size = UDim2.fromScale(0, 1),
								AutomaticSize = Enum.AutomaticSize.X,
								BackgroundTransparency = 1,
								LayoutOrder = 1,
								Text = props.maxed and "Maxed" or ("Cost: " .. NumberFormat.Format(props.cost)),
								Font = Theme.Fonts.Body,
								TextScaled = false,
								TextSize = 16,
								TextColor3 = props.canAfford and Theme.Colors.Gold or Theme.Colors.TextSecondary,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							Declare.New("ImageLabel")({
								Name = "CostIcon",
								Size = UDim2.fromScale(0.8, 0.8),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								BackgroundTransparency = 1,
								LayoutOrder = 2,
								Image = AssetIds.CookieMini,
								ScaleType = Enum.ScaleType.Fit,
								Visible = not props.maxed,
							}),
							-- Secondary cupcake (milestone) cost — shown only when the next
							-- purchase triggers a milestone (6.4).
							Declare.TextLabel({
								Name = "CupcakeCostText",
								Size = UDim2.fromScale(0, 1),
								AutomaticSize = Enum.AutomaticSize.X,
								BackgroundTransparency = 1,
								LayoutOrder = 3,
								Text = "+ " .. NumberFormat.Format(cupcakeCost),
								Font = Theme.Fonts.Body,
								TextScaled = false,
								TextSize = 14,
								TextColor3 = Theme.Colors.TextSecondary,
								TextXAlignment = Enum.TextXAlignment.Left,
								Visible = cupcakeCost > 0 and not props.maxed,
							}),
							Declare.New("ImageLabel")({
								Name = "CupcakeCostIcon",
								Size = UDim2.fromScale(0.6, 0.6),
								SizeConstraint = Enum.SizeConstraint.RelativeYY,
								BackgroundTransparency = 1,
								LayoutOrder = 4,
								Image = AssetIds.Cupcake,
								ScaleType = Enum.ScaleType.Fit,
								Visible = cupcakeCost > 0 and not props.maxed,
							})
						}
					}),
				}
			})
		}
	})

	-- ── Themed interaction states (Item 5b) ──────────────────────────────────
	-- Affordability is owned by UISystem and pushed via the "Affordable" attribute
	-- so a per-tick refresh never stomps the transient hover/press tint.
	btn:SetAttribute("Affordable", props.canAfford)
	btn:SetAttribute("Maxed", props.maxed == true)

	local hovered = false
	local pressed = false
	local held = false
	local holdToken = 0 -- generation guard so only the newest hold loop survives

	local function isMaxed(): boolean
		return btn:GetAttribute("Maxed") == true
	end

	local function targetColor(): Color3
		if isMaxed() then
			return Theme.Colors.Maxed
		end
		if btn:GetAttribute("Affordable") ~= true then
			return Theme.Colors.BackgroundCream
		end
		if pressed then
			return Theme.Colors.UpgradePressed
		end
		if hovered then
			return Theme.Colors.UpgradeHover
		end
		return Theme.Colors.Cream
	end

	local function applyColor()
		TweenService:Create(btn, HOVER_TWEEN, { BackgroundColor3 = targetColor() }):Play()
	end

	btn:GetAttributeChangedSignal("Affordable"):Connect(applyColor)
	btn:GetAttributeChangedSignal("Maxed"):Connect(applyColor)
	btn.MouseEnter:Connect(function()
		hovered = true
		applyColor()
	end)
	btn.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		held = false -- releasing the cursor off the button aborts a fast-buy hold
		applyColor()
	end)

	-- ── Fast-buy: hold to repeat-purchase (Item 5a) ─────────────────────────
	-- One press = one purchase (MouseButton1Down). Holding past FAST_BUY_HOLD_DELAY
	-- fires onClick every FAST_BUY_CADENCE until release or the safety cap. The
	-- server still validates each request independently (no bulk path).
	btn.MouseButton1Down:Connect(function()
		if isMaxed() then return end
		holdToken += 1
		local myToken = holdToken
		held = true
		pressed = true
		applyColor()

		task.spawn(function()
			local fired = 0
			props.onClick()
			fired += 1
			task.wait(Constants.FAST_BUY_HOLD_DELAY)
			while held and myToken == holdToken and fired < Constants.FAST_BUY_CAP do
				props.onClick()
				fired += 1
				task.wait(Constants.FAST_BUY_CADENCE)
			end
		end)
	end)

	local function stopHold()
		held = false
		pressed = false
		applyColor()
	end
	btn.MouseButton1Up:Connect(stopHold)

	return btn
end

return UpgradeButton
