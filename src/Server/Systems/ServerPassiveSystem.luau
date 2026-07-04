--!strict
-- Server-authoritative passive income. The client PassiveSystem is now pure
-- prediction; THIS is the source of truth that purchases are validated against.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local Constants = require(ReplicatedStorage.Shared.Constants)
local EconomyMath = require(ReplicatedStorage.Shared.Util.EconomyMath)
local PlayerEffectsService = require(script.Parent.PlayerEffectsService)

local ServerPassiveSystem = {}

-- Per-player wall-clock of the last credited accrual. In-memory only: we credit
-- elapsed real time while online, reset on join, so a rejoin never double-credits
-- and tick jitter never over/under-pays.
local lastAccrual: { [Player]: number } = {}

function ServerPassiveSystem.Init()
	Players.PlayerAdded:Connect(function(player: Player)
		lastAccrual[player] = os.clock()
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastAccrual[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		lastAccrual[player] = os.clock()
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < Constants.PASSIVE_TICK_INTERVAL then return end
		acc = 0

		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			-- Always advance the clock so time spent before the profile loads is
			-- never credited (no startup burst).
			local last = lastAccrual[player] or now
			lastAccrual[player] = now

			local data = DataService.GetProfileData(player)
			if not data then continue end

			local perSecond = EconomyMath.ComputePassivePerSecond(data)
			if perSecond <= 0 then continue end

			-- Cookie gamepass multipliers apply to passive income too (default 1.0).
			local cookieMult = PlayerEffectsService:GetMultiplier(player, "Cookie")
			DataService.AddCurrency(player, perSecond * (now - last) * cookieMult)
			-- Quests: count passive ticks + peak-currency checks (7c).
			require(script.Parent.QuestService).RecordPassiveTick(player)
		end
	end)
end

return ServerPassiveSystem
