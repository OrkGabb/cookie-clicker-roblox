--!strict
-- Shared themed CTA button — single source of truth for the mint-green action
-- button used by Shop (Buy/Owned) and Daily Rewards (Claim Reward). It is a
-- native TextButton (Frame + UICorner + UIStroke + engine font), never a raster
-- ImageButton, so it renders crisp at every viewport size. The font matches the
-- rest of the UI (Theme.Fonts.Display = Enum.Font.FredokaOne) — a built-in font
-- the engine rasterizes per-resolution, unlike a dynamically-loaded FontFace
-- which can render soft on larger screens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)

export type ButtonProps = {
	text: string,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
	textSize: number?,
	fillColor: Color3?,
	textColor: Color3?,
	enabled: boolean?, -- gates AutoButtonColor, Active, and the onClick callback (default true)
	flexMode: Enum.UIFlexMode?,
	onClick: (() -> ())?,
}

local function Button(props: ButtonProps): TextButton
	local enabled = if props.enabled == nil then true else props.enabled

	local children: { Instance } = {
		Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
		Declare.UIStroke({ Color = Theme.Colors.Cocoa, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	}
	if props.flexMode then
		table.insert(children, Declare.UIFlexItem({ FlexMode = props.flexMode }))
	end

	return Declare.New("TextButton")({
		Name = "Button",
		Size = props.size or UDim2.new(0, 110, 1, -20),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = props.fillColor or Theme.Colors.Mint,
		Text = props.text,
		Font = Theme.Fonts.Display,
		TextSize = props.textSize or 18,
		TextColor3 = props.textColor or Theme.Colors.Cocoa,
		AutoButtonColor = enabled,
		Active = enabled,
		Children = children,
		Events = {
			Activated = function()
				if enabled and props.onClick then
					props.onClick()
				end
			end,
		},
	}) :: TextButton
end

return Button
