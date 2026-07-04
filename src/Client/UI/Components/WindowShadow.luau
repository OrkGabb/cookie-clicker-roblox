--!strict
local Declare = require(script.Parent.Parent.Declare)

local function WindowShadow(): Instance
	return Declare.ImageLabel({
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(47, 47, 450, 450),
		Size = UDim2.new(1, 47, 1, 47),
		Position = UDim2.fromOffset(-23.5, -23.5),
		ZIndex = -1,
	})
end

return WindowShadow
