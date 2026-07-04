--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local WindowPanel = require(script.Parent.Parent.Components.WindowPanel)
local Button = require(script.Parent.Parent.Components.Button)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local DailyRewardConfig = require(ReplicatedStorage.Shared.Config.DailyRewardConfig)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)

local function DailyRewardsPanel(props: {
	currentStreak: number,
	canClaim: boolean,
	onClaimAction: () -> (),
	onClose: () -> ()
}): Instance

	local dayIndex = if props.currentStreak == 0 then 1 else ((props.currentStreak - 1) % 7) + 1

	local cards: {Instance} = {
		Declare.New("UIGridLayout")({
			CellSize = UDim2.new(1, -20, 0, 80),
			CellPadding = UDim2.new(0, 0, 0, Theme.Padding.Standard.Offset),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Declare.UIPadding({
			PaddingTop = Theme.Padding.Standard,
			PaddingBottom = Theme.Padding.Standard,
		})
	}
	
	for _, def in ipairs(DailyRewardConfig) do
		local isClaimed = false
		local isCurrent = false
		local isFuture = false
		
		if def.day < dayIndex then
			isClaimed = true
		elseif def.day == dayIndex then
			if not props.canClaim then
				isClaimed = true
			else
				isCurrent = true
			end
		else
			isFuture = true
		end
		
		local bgColor = Theme.Colors.BackgroundCream
		local borderColor = Theme.Colors.Cocoa
		local textAlpha = 0
		
		if isClaimed then
			borderColor = Theme.Colors.Success
		elseif isCurrent then
			bgColor = Theme.Colors.HeaderPink
		elseif isFuture then
			textAlpha = 0.5
		end
		
		table.insert(cards, Declare.Frame({
			LayoutOrder = def.day,
			BackgroundColor3 = bgColor,
			Children = {
				Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
				Declare.UIStroke({ Color = borderColor, Thickness = 2 }),
				Declare.UIPadding({
					PaddingLeft = Theme.Padding.Standard,
					PaddingRight = Theme.Padding.Standard,
				}),
				Declare.UIListLayout({
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = Theme.Padding.Standard,
				}),
				Declare.TextLabel({
					Size = UDim2.new(0, 60, 1, 0),
					BackgroundTransparency = 1,
					Text = "Day " .. def.day,
					Font = Theme.Fonts.Display,
					TextSize = 20,
					TextColor3 = Theme.Colors.TextPrimary,
					TextTransparency = textAlpha,
				}),
				Declare.TextLabel({
					Size = UDim2.new(1, -60, 1, 0),
					BackgroundTransparency = 1,
					Text = "+" .. NumberFormat.Format(def.rewardAmount) .. " " .. (def.rewardType == "Currency" and "Cookies" or def.rewardType),
					Font = Theme.Fonts.Body,
					TextSize = 18,
					TextColor3 = Theme.Colors.TextSecondary,
					TextTransparency = textAlpha,
					TextXAlignment = Enum.TextXAlignment.Right,
				})
			}
		}))
	end

	-- Shared CTA widget (same crisp native button as Shop's Buy). No bespoke
	-- raster/FontFace styling here — DRY, and renders sharp on every viewport.
	local claimButton = Button({
		size = UDim2.new(1, -40, 0, 50),
		position = UDim2.new(0.5, 0, 1, -20),
		anchorPoint = Vector2.new(0.5, 1),
		text = props.canClaim and "Claim Reward" or "Come Back Tomorrow",
		textSize = 28,
		fillColor = props.canClaim and Theme.Colors.Mint or Theme.Colors.BackgroundCream,
		textColor = props.canClaim and Theme.Colors.Cocoa or Theme.Colors.TextSecondary,
		enabled = props.canClaim,
		onClick = props.onClaimAction,
	})

	local content = Declare.Frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Children = {
			Declare.ScrollingFrame({
				Size = UDim2.new(1, 0, 1, -80),
				BackgroundTransparency = 1,
				ScrollBarThickness = 6,
				CanvasSize = UDim2.new(0, 0, 0, #DailyRewardConfig * 90 + 20),
				Children = cards
			}),
			claimButton
		}
	})

	return WindowPanel({
		title = "Daily Rewards",
		children = { content },
		onClose = props.onClose
	})
end

return DailyRewardsPanel
