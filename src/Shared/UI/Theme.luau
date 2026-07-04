--!strict
local Theme = {
	Colors = {
		-- Cookie / chocolate / cupcake palette (SSoT)
		Cream = Color3.fromHex("#F5E6D3"),       -- warm cookie base
		Blush = Color3.fromHex("#F4B8C4"),       -- cupcake pink
		Lavender = Color3.fromHex("#F0DEC9"),    -- white-chocolate
		Cocoa = Color3.fromHex("#7B4B36"),       -- chocolate (borders/primary)
		Gold = Color3.fromHex("#C8893E"),        -- caramel/gold (readable on cream)
		Mint = Color3.fromHex("#C8F5E8"),        -- soft pastel accent
		Rose = Color3.fromHex("#E8728C"),
		Peach = Color3.fromHex("#FFDAB9"),
		Dusk = Color3.fromHex("#A98A74"),        -- muted cocoa

		-- Semantics
		HeaderPink = Color3.fromHex("#F4B8C4"),       -- cupcake pink header
		BackgroundCream = Color3.fromHex("#EADBC8"),  -- dimmed cream (unaffordable/disabled card)
		PanelLavender = Color3.fromHex("#F7E3D0"),    -- warm panel
		TextPrimary = Color3.fromHex("#7B4B36"),
		TextSecondary = Color3.fromHex("#A98A74"),
		TextMuted = Color3.fromHex("#B8A38F"),
		Success = Color3.fromHex("#BCE3C5"),
		Warning = Color3.fromHex("#E8B04B"),
		Danger = Color3.fromHex("#E8728C"),

		-- Upgrade card interaction states (Item 5b)
		UpgradeHover = Color3.fromHex("#D4A574"),     -- warm cinnamon highlight
		UpgradePressed = Color3.fromHex("#C28A56"),   -- deeper cinnamon
		Maxed = Color3.fromHex("#C7C2BC"),            -- reserved muted gray (Maxed state only)
	},
	Fonts = {
		Display = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamMedium,
	},
	Corners = {
		Standard = UDim.new(0, 12),
		Small = UDim.new(0, 8),
		Large = UDim.new(0, 16),
	},
	Padding = {
		Standard = UDim.new(0, 10),
		Small = UDim.new(0, 4),
		Large = UDim.new(0, 20),
	},
	Sizes = {
		-- Max width (px) of a Sidebar icon button. SSoT — adjust here, never per-icon.
		SidebarIcon = 103, -- ≈ +14% over the previous 90 (room freed by moving Achievements into Quests)
	},
}

return Theme
