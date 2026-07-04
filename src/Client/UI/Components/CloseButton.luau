--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Declare = require(script.Parent.Parent.Declare)
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)

local function CloseButton(props: { onClick: () -> () }): Instance
	local btn = Declare.New("ImageButton")({
		Name = "CloseButton",
		Size = UDim2.fromOffset(32, 32),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -15, 0.5, 0),
		BackgroundTransparency = 1,
		Image = AssetIds.CloseButtonEgg,
		ScaleType = Enum.ScaleType.Fit,
		Events = {
			MouseButton1Click = props.onClick
		}
	})
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { Size = UDim2.fromOffset(36, 36) }):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { Size = UDim2.fromOffset(32, 32) }):Play()
	end)
	
	return btn
end

return CloseButton
