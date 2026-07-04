--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local Types = require(ReplicatedStorage.Shared.Types)
local WindowPanel = require(script.Parent.Parent.Components.WindowPanel)
local TabBar = require(script.Parent.Parent.Components.TabBar)
local AchievementsList = require(script.Parent.AchievementsList)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local QuestConfig = require(ReplicatedStorage.Shared.Config.QuestConfig)

local TIER_COLOR = {
	easy = Theme.Colors.Success,
	medium = Theme.Colors.Gold,
	hard = Theme.Colors.Rose,
}

local function QuestPanel(props: {
	completed: { [string]: boolean },
	progress: { [string]: number },
	stats: Types.PlayerStats,
	hasAchievement: (id: string) -> boolean,
	onClose: () -> ()
}): Instance

	local cards: { Instance } = {
		Declare.New("UIGridLayout")({
			CellSize = UDim2.new(1, -20, 0, 110),
			CellPadding = UDim2.new(0, 0, 0, Theme.Padding.Standard.Offset),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		Declare.UIPadding({
			PaddingTop = Theme.Padding.Large,
			PaddingBottom = Theme.Padding.Large,
			PaddingLeft = Theme.Padding.Standard,
			PaddingRight = Theme.Padding.Standard,
		}),
	}

	for i, def in ipairs(QuestConfig) do
		local isDone = props.completed[def.id] == true
		local current = props.progress[def.id] or 0
		local pct = math.clamp(current / def.target, 0, 1)
		local tierColor = TIER_COLOR[def.tier] or Theme.Colors.Gold

		local nameText = isDone and ("\u{2713} " .. def.name) or def.name
		local nameColor = isDone and Theme.Colors.Success or Theme.Colors.TextPrimary
		local bodyAlpha = isDone and 0.4 or 0

		local progressBar = Declare.Frame({
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundColor3 = Theme.Colors.BackgroundCream,
			BackgroundTransparency = bodyAlpha,
			Children = {
				Declare.UICorner({ CornerRadius = UDim.new(1, 0) }),
				Declare.Frame({
					Size = UDim2.fromScale(pct, 1),
					BackgroundColor3 = isDone and Theme.Colors.Success or tierColor,
					Children = { Declare.UICorner({ CornerRadius = UDim.new(1, 0) }) }
				})
			}
		})

		table.insert(cards, Declare.Frame({
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Colors.Cream,
			BackgroundTransparency = isDone and 0.35 or 0,
			LayoutOrder = isDone and (i + 100) or i, -- active quests float to top
			Children = {
				Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
				Declare.UIPadding({
					PaddingTop = Theme.Padding.Standard,
					PaddingBottom = Theme.Padding.Standard,
					PaddingLeft = Theme.Padding.Standard,
					PaddingRight = Theme.Padding.Standard,
				}),
				Declare.UIListLayout({
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				-- Title row: name (left) + reward (right)
				Declare.Frame({
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Children = {
						Declare.New("ImageLabel")({
							Name = "QuestIcon",
							Size = UDim2.fromOffset(24, 24),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							BackgroundTransparency = 1,
							Image = AssetIds.Quest,
							ImageTransparency = bodyAlpha,
							ScaleType = Enum.ScaleType.Fit,
						}),
						Declare.TextLabel({
							Size = UDim2.new(0.7, -30, 1, 0),
							Position = UDim2.fromOffset(30, 0),
							BackgroundTransparency = 1,
							Text = nameText,
							Font = Theme.Fonts.Display,
							TextSize = 22,
							TextColor3 = nameColor,
							TextTransparency = bodyAlpha,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						Declare.Frame({
							Size = UDim2.new(0.3, 0, 1, 0),
							Position = UDim2.fromScale(0.7, 0),
							BackgroundTransparency = 1,
							Children = {
								Declare.UIListLayout({
									FillDirection = Enum.FillDirection.Horizontal,
									HorizontalAlignment = Enum.HorizontalAlignment.Right,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									Padding = UDim.new(0, 2),
									SortOrder = Enum.SortOrder.LayoutOrder,
								}),
								Declare.TextLabel({
									Size = UDim2.fromScale(0, 1),
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundTransparency = 1,
									LayoutOrder = 1,
									Text = "+" .. tostring(def.reward),
									Font = Theme.Fonts.Display,
									TextSize = 20,
									TextColor3 = tierColor,
									TextTransparency = bodyAlpha,
								}),
								Declare.New("ImageLabel")({
									Size = UDim2.fromScale(0.7, 0.7),
									SizeConstraint = Enum.SizeConstraint.RelativeYY,
									BackgroundTransparency = 1,
									LayoutOrder = 2,
									Image = AssetIds.Cupcake,
									ImageTransparency = bodyAlpha,
									ScaleType = Enum.ScaleType.Fit,
								})
							}
						})
					}
				}),
				Declare.TextLabel({
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Text = def.description,
					Font = Theme.Fonts.Body,
					TextSize = 15,
					TextColor3 = Theme.Colors.TextSecondary,
					TextTransparency = bodyAlpha,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Declare.Frame({
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Children = {
						Declare.UIListLayout({
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = Theme.Padding.Small,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
						Declare.Frame({
							Size = UDim2.new(0.65, 0, 1, 0),
							BackgroundTransparency = 1,
							LayoutOrder = 1,
							Children = {
								Declare.UIListLayout({ VerticalAlignment = Enum.VerticalAlignment.Center }),
								progressBar
							}
						}),
						Declare.TextLabel({
							Size = UDim2.new(0.35, -8, 1, 0),
							BackgroundTransparency = 1,
							LayoutOrder = 2,
							Text = NumberFormat.Format(math.min(current, def.target)) .. " / " .. NumberFormat.Format(def.target),
							Font = Theme.Fonts.Body,
							TextSize = 14,
							TextColor3 = Theme.Colors.TextSecondary,
							TextTransparency = bodyAlpha,
							TextXAlignment = Enum.TextXAlignment.Right,
						})
					}
				})
			}
		}))
	end

	local questsList = Declare.ScrollingFrame({
		Name = "QuestsTabContent",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Children = cards
	})

	-- Second tab content: the Achievements view reused verbatim (no duplicated logic).
	local achievementsList = AchievementsList({
		stats = props.stats,
		hasAchievement = props.hasAchievement,
	})
	achievementsList.Visible = false

	-- Header label is owned by WindowPanel; captured after creation so the title can
	-- follow the active tab.
	local headerLabel: TextLabel? = nil
	local TAB_TITLES = { "Quests", "Achievements" }

	-- Top-right tab bar switches the two views in place (panel stays open). Labels are
	-- passed in, so TabBar itself stays generic.
	local tabBar = TabBar({
		tabs = TAB_TITLES,
		onTab = function(index: number)
			questsList.Visible = index == 1
			achievementsList.Visible = index == 2
			if headerLabel then
				headerLabel.Text = TAB_TITLES[index]
			end
		end,
	})

	-- Both lists occupy the same area; only one is Visible at a time. UIFlexItem(Fill)
	-- makes this holder consume the height left over by the tab bar row above it.
	local listsHolder = Declare.Frame({
		Name = "TabContent",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Children = {
			Declare.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
			-- Right inset so the list scrollbars sit inside the rounded window edge
			-- instead of clipping against it.
			Declare.UIPadding({ PaddingRight = Theme.Padding.Large }),
			questsList,
			achievementsList,
		}
	})

	-- tabBar (full-width, right-aligned internally) gets a fixed height in the column.
	tabBar.LayoutOrder = 1

	local container = Declare.Frame({
		Name = "QuestsTabbed",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Children = {
			Declare.UIListLayout({
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Theme.Padding.Small,
			}),
			tabBar,
			listsHolder,
		}
	})

	local window = WindowPanel({
		title = "Quests",
		children = { container },
		onClose = props.onClose
	})

	-- Capture WindowPanel's title label so onTab can rename it to the active tab.
	headerLabel = window:FindFirstChild("Title", true) :: TextLabel?

	return window
end

return QuestPanel
