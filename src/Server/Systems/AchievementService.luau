--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local AchievementConfig = require(ReplicatedStorage.Shared.Config.AchievementConfig)
local DataService = require(script.Parent.Parent.Services.DataService)

local AchievementService = {}

local achievementUnlockedRemote: RemoteEvent
local achievementRewardRemote: RemoteEvent

local REWARD_DELAY = 2 -- seconds between the unlock toast and crediting the reward (7e)

function AchievementService.Init()
	local allRemotes = require(ReplicatedStorage.Shared.Remotes)
	achievementUnlockedRemote = (allRemotes :: any).AchievementUnlocked :: RemoteEvent
	achievementRewardRemote = (allRemotes :: any).AchievementReward :: RemoteEvent
end

-- Credits an unlocked achievement's reward after a short delay so the client can show
-- the "unlocked" toast first, then a separate "reward" toast (7e).
local function grantRewardDelayed(player: Player, def: Types.AchievementDefinition)
	task.delay(REWARD_DELAY, function()
		local data = DataService.GetProfileData(player)
		if not data then return end -- player left during the delay

		if def.rewardType == "Currency" then
			DataService.AddCurrency(player, def.rewardAmount)
		elseif def.rewardType == "Cosmetic" and def.rewardSkinId then
			local found = false
			for _, skin in ipairs(data.unlockedSkins) do
				if skin == def.rewardSkinId then found = true break end
			end
			if not found then
				table.insert(data.unlockedSkins, def.rewardSkinId)
			end
		end

		achievementRewardRemote:FireClient(player, def.id, def.rewardType, def.rewardAmount)
	end)
end

function AchievementService.RecordStat(player: Player, statKey: string, amount: number)
	local data = DataService.GetProfileData(player)
	if not data then return end

	local currentVal = (data.stats :: any)[statKey]
	if type(currentVal) ~= "number" then return end
	
	local newVal = currentVal + amount
	local statsAny: any = data.stats
	statsAny[statKey] = newVal
	
	-- Keep alias synced for backward compatibility
	if statKey == "lifetimeCookies" then
		data.lifetimeCookies = newVal
	end

	for _, def in ipairs(AchievementConfig) do
		if def.statKey == statKey then
			if not data.unlockedAchievements[def.id] and newVal >= def.threshold then
				data.unlockedAchievements[def.id] = true

				-- 7e: announce the unlock now (no credit), credit the reward after a delay.
				achievementUnlockedRemote:FireClient(player, def.id)
				grantRewardDelayed(player, def)
			end
		end
	end
end

return AchievementService
