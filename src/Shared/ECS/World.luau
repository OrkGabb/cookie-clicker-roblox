--!strict
local RunService = game:GetService("RunService")
local Maid       = require(script.Parent.Parent.Util.Maid)
export type World = {
	new: (systems: { any }) -> World,
	Update: (self: World, dt: number) -> (),
	Destroy: (self: World) -> (),
}
local World = {}
World.__index = World
function World.new(systems: { any }): World
	local self = setmetatable({}, World) :: any
	self._systems = systems
	self._maid    = Maid.new()
	for _, s in ipairs(systems) do
		if (s :: any).Init then (s :: any):Init() end
	end
	self._maid:Give(RunService.RenderStepped:Connect(function(dt: number)
		self:Update(dt)
	end))
	return self
end
function World:Update(dt: number)
	for _, s in ipairs(self._systems :: { any }) do
		if (s :: any).Update then (s :: any):Update(dt) end
	end
end
function World:Destroy()
	self._maid:Destroy()
	for _, s in ipairs(self._systems :: { any }) do
		if (s :: any).Destroy then (s :: any):Destroy() end
	end
end
return World
