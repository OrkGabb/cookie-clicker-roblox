--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local Constants = require(ReplicatedStorage.Shared.Constants)
local DailyRewardConfig = require(ReplicatedStorage.Shared.Config.DailyRewardConfig)
local AchievementService = require(script.Parent.AchievementService)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)

local DailyRewardService = {}

function DailyRewardService.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local claimDailyReward = (Remotes :: any).ClaimDailyReward :: RemoteFunction
	
	claimDailyReward.OnServerInvoke = function(player: Player)
		if not RateLimiter.Check(player, "ClaimDailyReward", 1, 5) then
			return { success = false, newStreak = 0, newTimestamp = 0, message = "Rate limited" }
		end
		
		local data = DataService.GetProfileData(player)
		if not data then 
			return { success = false, newStreak = 0, newTimestamp = 0, message = "Profile not loaded" }
		end
		
		local now = os.time()
		local delta = now - data.lastClaimTimestamp
		
		if data.lastClaimTimestamp ~= 0 and delta < Constants.DAILY_REWARD_COOLDOWN then
			return { success = false, newStreak = data.stats.dailyStreak, newTimestamp = data.lastClaimTimestamp, message = "Already claimed today" }
		end
		
		if data.lastClaimTimestamp ~= 0 and delta > Constants.DAILY_REWARD_GRACE_PERIOD then
			-- Break streak
			local statsAny: any = data.stats
			statsAny.dailyStreak = 0
		end
		
		-- Increment streak via achievement service
		AchievementService.RecordStat(player, "dailyStreak", 1)
		
		-- Update timestamp
		data.lastClaimTimestamp = now
		
		-- Fetch reward config
		local currentStreak = data.stats.dailyStreak
		local dayIndex = if currentStreak == 0 then 1 else ((currentStreak - 1) % 7) + 1
		
		local rewardDef = nil
		for _, def in ipairs(DailyRewardConfig) do
			if def.day == dayIndex then
				rewardDef = def
				break
			end
		end
		
		local awarded = 0
		if rewardDef then
			if rewardDef.rewardType == "Currency" then
				DataService.AddCurrency(player, rewardDef.rewardAmount)
				awarded = rewardDef.rewardAmount
			end
		end

		return { success = true, newStreak = currentStreak, newTimestamp = now, rewardAmount = awarded, message = "Reward claimed!" }
	end
end

return DailyRewardService
