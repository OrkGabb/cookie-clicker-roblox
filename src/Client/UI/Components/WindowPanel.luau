--!strict
local Declare = require(script.Parent.Parent.Declare)
local WindowShadow = require(script.Parent.WindowShadow)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local CloseButton = require(script.Parent.CloseButton)

local function WindowPanel(props: {
	title: string,
	children: {Instance},
	onClose: () -> ()
}): Instance

	local isClosing = false
	local scaler = Instance.new("UIScale")
	scaler.Name = "Scaler"
	scaler.Scale = 0
	
	local function handleClose()
		if isClosing then return end
		isClosing = true
		local t = TweenService:Create(scaler, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		t.Completed:Connect(props.onClose)
		t:Play()
	end

	local blocker = Declare.New("TextButton")({
		Name = "WindowBlocker",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 100,
		Events = {
			MouseButton1Click = handleClose
		},
		Children = {
			Declare.New("TextButton")({
				Name = "WindowContainer",
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- Raised ~20px so panels sit centered/slightly high (clear of bottom edge).
				Position = UDim2.new(0.5, 0, 0.5, -20),
				Size = UDim2.fromScale(0.8, 0.8),
				BackgroundColor3 = Theme.Colors.BackgroundCream,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 101,
				Events = {
					MouseButton1Click = function() end
				},
				Children = {
					scaler,
					Declare.UICorner({ CornerRadius = Theme.Corners.Large }),
					Declare.UISizeConstraint({
						MaxSize = Vector2.new(800, 600),
						MinSize = Vector2.new(300, 400),
					}),
					WindowShadow(),
					
					Declare.Frame({
						Name = "Header",
						Size = UDim2.new(1, 0, 0, 60),
						BackgroundTransparency = 1,
						Children = {
							Declare.TextLabel({
								Name = "Title",
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								Text = props.title,
								Font = Theme.Fonts.Display,
								TextSize = 32,
								TextColor3 = Theme.Colors.TextPrimary,
							}),
							CloseButton({ onClick = handleClose })
						}
					}),
					
					Declare.Frame({
						Name = "Content",
						Size = UDim2.new(1, 0, 1, -60),
						Position = UDim2.fromOffset(0, 60),
						BackgroundTransparency = 1,
						Children = props.children
					})
				}
			})
		}
	})
	
	TweenService:Create(scaler, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	
	return blocker
end

return WindowPanel
