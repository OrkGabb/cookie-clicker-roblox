--!strict
-- @author OrkGabb
-- Achievements content list (cards + scrolling frame) WITHOUT a window chrome. Rendered by
-- the Achievements tab inside QuestPanel (DRY/SSoT — one source for the view). Achievements
-- data/logic still lives in AchievementService/AchievementConfig — this is presentation only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local Types = require(ReplicatedStorage.Shared.Types)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local AchievementConfig = require(ReplicatedStorage.Shared.Config.AchievementConfig)

local function AchievementsList(props: {
	stats: Types.PlayerStats,
	hasAchievement: (id: string) -> boolean,
}): Instance

	local cards: {Instance} = {
		Declare.New("UIGridLayout")({
			CellSize = UDim2.new(1, -20, 0, 100),
			CellPadding = UDim2.new(0, 0, 0, Theme.Padding.Standard.Offset),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Declare.UIPadding({
			PaddingTop = Theme.Padding.Large,
			PaddingBottom = Theme.Padding.Large,
			PaddingLeft = Theme.Padding.Standard,
			PaddingRight = Theme.Padding.Standard,
		})
	}

	for i, def in ipairs(AchievementConfig) do
		local isUnlocked = props.hasAchievement(def.id)
		local currentVal = (props.stats :: any)[def.statKey] or 0
		if type(currentVal) ~= "number" then currentVal = 0 end

		local progress = math.min(currentVal / def.threshold, 1)

		local iconColor = isUnlocked and Color3.new(1, 1, 1) or Color3.new(0.5, 0.5, 0.5)
		local titleColor = isUnlocked and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
		local titleText = isUnlocked and def.title or "Locked"

		local progressBar = Declare.Frame({
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundColor3 = Theme.Colors.BackgroundCream,
			Children = {
				Declare.UICorner({ CornerRadius = UDim.new(1, 0) }),
				Declare.Frame({
					Size = UDim2.fromScale(progress, 1),
					BackgroundColor3 = Theme.Colors.Mint,
					Children = {
						Declare.UICorner({ CornerRadius = UDim.new(1, 0) })
					}
				})
			}
		})

		local card = Declare.Frame({
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Colors.Cream,
			LayoutOrder = isUnlocked and (i - 100) or i, -- unlocked ones float to top
			Children = {
				Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
				Declare.UIListLayout({
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = Theme.Padding.Standard,
				}),
				Declare.UIPadding({
					PaddingTop = Theme.Padding.Standard,
					PaddingBottom = Theme.Padding.Standard,
					PaddingLeft = Theme.Padding.Standard,
					PaddingRight = Theme.Padding.Standard,
				}),

				-- Icon
				Declare.New("ImageLabel")({
					Size = UDim2.new(0, 60, 0, 60),
					BackgroundTransparency = 1,
					Image = def.icon,
					ImageColor3 = iconColor,
					ScaleType = Enum.ScaleType.Fit,
				}),

				-- Content
				Declare.Frame({
					Size = UDim2.new(1, -80, 1, 0),
					BackgroundTransparency = 1,
					Children = {
						Declare.UIListLayout({
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 4)
						}),
						Declare.TextLabel({
							Size = UDim2.new(1, 0, 0, 24),
							BackgroundTransparency = 1,
							Text = titleText,
							Font = Theme.Fonts.Display,
							TextSize = 22,
							TextColor3 = titleColor,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						Declare.TextLabel({
							Size = UDim2.new(1, 0, 0, 20),
							BackgroundTransparency = 1,
							Text = def.description,
							Font = Theme.Fonts.Body,
							TextSize = 16,
							TextColor3 = Theme.Colors.TextSecondary,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextWrapped = true,
						}),
						-- Progress text + bar wrapper
						Declare.Frame({
							Size = UDim2.new(1, 0, 0, 20),
							BackgroundTransparency = 1,
							LayoutOrder = 10,
							Children = {
								Declare.UIListLayout({
									FillDirection = Enum.FillDirection.Horizontal,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									Padding = Theme.Padding.Small,
								}),
								Declare.Frame({
									Size = UDim2.new(0.6, 0, 1, 0),
									BackgroundTransparency = 1,
									Children = {
										Declare.UIListLayout({ VerticalAlignment = Enum.VerticalAlignment.Center }),
										progressBar
									}
								}),
								Declare.TextLabel({
									Size = UDim2.new(0.4, -10, 1, 0),
									BackgroundTransparency = 1,
									Text = NumberFormat.Format(currentVal) .. " / " .. NumberFormat.Format(def.threshold),
									Font = Theme.Fonts.Body,
									TextSize = 14,
									TextColor3 = Theme.Colors.TextSecondary,
									TextXAlignment = Enum.TextXAlignment.Right,
								})
							}
						})
					}
				})
			}
		})

		table.insert(cards, card)
	end

	return Declare.ScrollingFrame({
		Name = "AchievementsList",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, #AchievementConfig * 110 + 20),
		Children = cards
	})
end

return AchievementsList
