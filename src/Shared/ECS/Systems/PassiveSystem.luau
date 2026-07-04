--!strict
local Signal = require(script.Parent.Parent.Parent.Util.Signal)
export type PassiveSystem = {
	TickEarned: Signal.Signal,
	new: (gameState: any) -> PassiveSystem,
	Init: (self: PassiveSystem) -> (),
	Update: (self: PassiveSystem, dt: number) -> (),
	Destroy: (self: PassiveSystem) -> (),
}
local PassiveSystem = {}
PassiveSystem.__index = PassiveSystem
function PassiveSystem.new(gameState: any): PassiveSystem
	local self = setmetatable({}, PassiveSystem) :: any
	self._gs          = gameState
	self._acc         = 0
	self.TickEarned   = Signal.new()
	return self
end
function PassiveSystem:Init() end
function PassiveSystem:Update(dt: number)
	local perSecond = self._gs:GetPerSecond()
	if perSecond <= 0 then return end
	self._acc += dt
	while self._acc >= 1 do
		self._gs:AddCurrency(perSecond)
		self._acc -= 1
		self.TickEarned:Fire(perSecond)
	end
end
function PassiveSystem:Destroy()
	self.TickEarned:Destroy()
end
return PassiveSystem
