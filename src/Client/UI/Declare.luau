--!strict
local Declare = {}

export type Props = {
	Children: {Instance}?,
	Events: {[string]: (...any) -> ()}?,
	[string]: any,
}

function Declare.New(className: string): (props: Props) -> Instance
	return function(props: Props): Instance
		local inst = Instance.new(className)
		
		for k, v in pairs(props) do
			if k == "Children" then
				if type(v) == "table" then
					for _, child in ipairs(v) do
						if child then
							child.Parent = inst
						end
					end
				end
			elseif k == "Events" then
				if type(v) == "table" then
					for eventName, callback in pairs(v) do
						local event = (inst :: any)[eventName]
						if event and typeof(event) == "RBXScriptSignal" then
							event:Connect(callback)
						end
					end
				end
			else
				(inst :: any)[k] = v
			end
		end
		
		return inst
	end
end

Declare.Frame = Declare.New("Frame")
Declare.TextLabel = Declare.New("TextLabel")
Declare.TextButton = Declare.New("TextButton")
Declare.ImageLabel = Declare.New("ImageLabel")
Declare.ImageButton = Declare.New("ImageButton")
Declare.ScrollingFrame = Declare.New("ScrollingFrame")
Declare.UIListLayout = Declare.New("UIListLayout")
Declare.UICorner = Declare.New("UICorner")
Declare.UIPadding = Declare.New("UIPadding")
Declare.UIStroke = Declare.New("UIStroke")
Declare.UIGradient = Declare.New("UIGradient")
Declare.UIAspectRatioConstraint = Declare.New("UIAspectRatioConstraint")
Declare.UIFlexItem = Declare.New("UIFlexItem")
Declare.UISizeConstraint = Declare.New("UISizeConstraint")
Declare.UITextSizeConstraint = Declare.New("UITextSizeConstraint")

return Declare
