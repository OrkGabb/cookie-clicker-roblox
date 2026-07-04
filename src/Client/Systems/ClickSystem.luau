--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(ReplicatedStorage.Shared.State.GameState)

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local SoundController = require(ReplicatedStorage.Shared.Util.SoundController)

local ClickSystem = {}
ClickSystem.__index = ClickSystem

function ClickSystem.new(state: GameState.GameState)
	local self = setmetatable({}, ClickSystem) :: any
	self._gs = state
	self._batchQueue = 0
	self._batchTimer = 0
	self.Clicked = Signal.new()
	
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	self._remote = (Remotes :: any).BatchedClicks :: RemoteEvent
	
	return self
end

function ClickSystem:Init() end

function ClickSystem:RegisterClick()
	local now = os.clock()
	if now - self._gs.ClickerInput.lastClick >= self._gs.ClickerInput.cooldown then
		self._gs.ClickerInput.lastClick = now
		self._gs.ClickerInput.sessionClicks += 1
		self._gs.ClickerInput.totalClicks += 1
		
		local gain = self._gs:GetPerClick()
		self._gs:AddCurrency(gain)
		
		self._batchQueue += 1
		self.Clicked:Fire(gain)
		SoundController.PlayClickSound()
	end
end

function ClickSystem:Update(dt: number)
	if self._batchQueue > 0 then
		self._batchTimer += dt
		if self._batchTimer >= 0.5 then
			self._remote:FireServer(self._batchQueue)
			self._batchQueue = 0
			self._batchTimer = 0
		end
	end
end

function ClickSystem:Destroy() end

return ClickSystem
