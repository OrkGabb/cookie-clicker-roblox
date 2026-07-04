--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local GoldenCookieConfig = require(ReplicatedStorage.Shared.Config.GoldenCookieConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local EffectRegistry = require(ReplicatedStorage.Shared.ECS.Systems.EffectRegistry)

local GoldenCookieService = {}
GoldenCookieService._activeCookies = {} :: { [Player]: { [string]: number } }

function GoldenCookieService.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local spawnRemote = (Remotes :: any).SpawnGoldenCookie :: RemoteEvent
	local claimRemote = (Remotes :: any).ClaimGoldenCookie :: RemoteFunction
	
	Players.PlayerAdded:Connect(function(player)
		GoldenCookieService._activeCookies[player] = {}
		task.spawn(function()
			while player:IsDescendantOf(Players) do
				local waitTime = math.random(GoldenCookieConfig.SpawnIntervalRange.Min, GoldenCookieConfig.SpawnIntervalRange.Max)

				-- 1s tick loops allows for Garbage Collection of missed cookies
				for i = 1, waitTime do
					task.wait(1)
					if not player:IsDescendantOf(Players) then return end
					
					local pCookies = GoldenCookieService._activeCookies[player]
					if pCookies then
						local currentTime = os.time()
						local maxLife = GoldenCookieConfig.DescentDuration + GoldenCookieConfig.DescentTolerance
						for guid, spawnTime in pairs(pCookies) do
							if currentTime - spawnTime > maxLife then
								pCookies[guid] = nil -- Stale cookie expired
							end
						end
					end
				end
				
				-- Single active cookie per player: drop any prior guid so only the newest
				-- is claimable (the client also replaces the old visual). Keeps the map
				-- bounded — no stack buildup even at the shortest 45s spawn interval.
				local pCookies = GoldenCookieService._activeCookies[player]
				if pCookies then
					table.clear(pCookies)
				end

				local guid = HttpService:GenerateGUID(false)
				GoldenCookieService._activeCookies[player][guid] = os.time()
				spawnRemote:FireClient(player, guid)
			end
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		GoldenCookieService._activeCookies[player] = nil
	end)
	
	claimRemote.OnServerInvoke = function(player: Player, guid: string)
		if typeof(guid) ~= "string" then return false end
		
		local playerCookies = GoldenCookieService._activeCookies[player]
		if not playerCookies or not playerCookies[guid] then
			return false
		end
		
		local spawnTime = playerCookies[guid]
		local currentTime = os.time()
		
		local maxLife = GoldenCookieConfig.DescentDuration + GoldenCookieConfig.DescentTolerance
		if currentTime - spawnTime > maxLife then
			playerCookies[guid] = nil
			return false
		end
		
		-- Valid claim, destroy cache to prevent double-claiming
		playerCookies[guid] = nil
		
		local data = DataService.GetProfileData(player)
		if not data then return false end

		-- Reward scales with the player's current passive income (CpS) so it stays
		-- meaningful at every progression stage instead of going stale as a flat number.
		local EconomyMath = require(ReplicatedStorage.Shared.Util.EconomyMath)
		local cps = EconomyMath.ComputePassivePerSecond(data)

		-- Weighted tier roll (independent per spawn, not cached per player).
		local totalWeight = 0
		for _, tier in ipairs(GoldenCookieConfig.RewardTiers) do
			totalWeight += tier.weight
		end

		local roll = math.random(1, totalWeight)
		local currentWeight = 0
		local selected = GoldenCookieConfig.RewardTiers[1]
		for _, tier in ipairs(GoldenCookieConfig.RewardTiers) do
			currentWeight += tier.weight
			if roll <= currentWeight then
				selected = tier
				break
			end
		end

		-- reward = max(floor, cpsSeconds * CpS), then apply the SAME gamepass Cookie
		-- multipliers a normal cookie gain respects (golden cookies are cookie gain).
		local PlayerEffectsService = require(script.Parent.PlayerEffectsService)
		local cookieMult = PlayerEffectsService:GetMultiplier(player, "Cookie")
		local base = math.max(selected.floor, selected.cpsSeconds * cps)
		local reward = math.floor(base * cookieMult)
		if reward < 1 then reward = 1 end

		local AchievementService = require(script.Parent.AchievementService)
		DataService.AddCurrency(player, reward)
		AchievementService.RecordStat(player, "goldenCookiesCollected", 1)

		-- Return tier alongside the amount so the client can differentiate the popup
		-- (bigger/glowier text for Rare/Jackpot).
		return { amount = reward, tier = selected.name }
	end
end

return GoldenCookieService
