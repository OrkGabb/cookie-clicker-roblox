--!strict
local Declare = require(script.Parent.Parent.Declare)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local SoundController = require(ReplicatedStorage.Shared.Util.SoundController)

local function SidebarButton(imageId: string, onClick: () -> ()): Instance
	return Declare.New("ImageButton")({
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundTransparency = 1,
		Image = imageId,
		ScaleType = Enum.ScaleType.Fit,
		Children = {
			Declare.UIFlexItem({ FlexMode = Enum.UIFlexMode.None }),
		},
		Events = {
			MouseButton1Click = function()
				SoundController.PlayUISound()
				onClick()
			end
		}
	})
end

local function Sidebar(props: {
	onShop: () -> (),
	onSettings: () -> (),
	onDailyReward: () -> (),
	onQuests: () -> (),
}): Instance

	return Declare.Frame({
		Name = "Sidebar",
		-- Taller frame + centered list so all icons (incl. Settings) fit without clipping.
		-- Y anchored at 0.54 (~4% below center) per the lower-sidebar tweak.
		Size = UDim2.new(0.08, 0, 0.75, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.54, -15),
		BackgroundTransparency = 1,
		Children = {
			-- Icon size comes from the Theme SSoT (not hardcoded per icon).
			Declare.UISizeConstraint({ MaxSize = Vector2.new(Theme.Sizes.SidebarIcon, 9999), MinSize = Vector2.new(50, 0) }),
			Declare.UIListLayout({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Theme.Padding.Standard,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			-- Top padding keeps the Shop button clear of the Roblox corner menu icon.
			Declare.Frame({
				Name = "TopPadding",
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				Children = { Declare.UIFlexItem({ FlexMode = Enum.UIFlexMode.None }) },
			}),
			-- Achievements lives inside the Quests panel now (tab), not as a solo icon.
			SidebarButton(AssetIds.Shop, props.onShop),
			SidebarButton(AssetIds.Quest, props.onQuests),
			SidebarButton(AssetIds.DailyReward, props.onDailyReward),
			SidebarButton(AssetIds.Settings, props.onSettings),
		}
	})
end

return Sidebar
