--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)
local CookieSquish = require(script.Parent.Parent.CookieSquish)

local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

local function ClickerArea(props: {
	skinDef: Types.SkinDefinition,
	onClick: () -> ()
}): Instance

	local btn = Declare.New("ImageButton")({
		Name = "TreatButton",
		Size = UDim2.fromScale(1.0, 1.0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = AssetIds.CookieMain,
		ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false,
		Children = {
			Declare.UIAspectRatioConstraint({ AspectRatio = 1 }),
			Declare.UISizeConstraint({
				MaxSize = Vector2.new(1000, 1000),
				MinSize = Vector2.new(200, 200),
			}),
		}
	})
	
	btn.MouseButton1Down:Connect(function()
		CookieSquish.Press(btn)
	end)

	btn.MouseButton1Up:Connect(function()
		CookieSquish.Release(btn)
	end)

	btn.MouseButton1Click:Connect(props.onClick)
	
	return btn
end

return ClickerArea
