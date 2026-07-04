--!strict
-- @author OrkGabb
-- Generic, reusable tab bar. Fully props-driven — no hardcoded tab labels (OCP), so any
-- panel can compose it. Tracks the active tab internally, highlights it with theme tokens,
-- and fires onTab(index) when the selection changes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)

local function TabBar(props: {
	tabs: { string },
	onTab: (index: number) -> (),
	initial: number?,
}): Instance
	local active = props.initial or 1
	local buttons: { TextButton } = {}

	local function refresh()
		for i, btn in ipairs(buttons) do
			local isActive = i == active
			btn.BackgroundColor3 = isActive and Theme.Colors.HeaderPink or Theme.Colors.BackgroundCream
			btn.TextColor3 = isActive and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
		end
	end

	local children: { Instance } = {
		Declare.UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = Theme.Padding.Small,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, label in ipairs(props.tabs) do
		local btn = Declare.New("TextButton")({
			Name = "Tab_" .. label,
			Size = UDim2.fromOffset(0, 32),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.Colors.BackgroundCream,
			Text = label,
			Font = Theme.Fonts.Display,
			TextSize = 18,
			TextColor3 = Theme.Colors.TextSecondary,
			LayoutOrder = i,
			Children = {
				Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
				Declare.UIPadding({
					PaddingLeft = Theme.Padding.Standard,
					PaddingRight = Theme.Padding.Standard,
				}),
			},
			Events = {
				MouseButton1Click = function()
					if active == i then return end
					active = i
					refresh()
					props.onTab(i)
				end,
			},
		})
		table.insert(buttons, btn)
		table.insert(children, btn)
	end

	refresh()

	return Declare.Frame({
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Children = children,
	})
end

return TabBar
