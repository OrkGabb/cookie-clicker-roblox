--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileService = require(script.Parent.Parent.Modules.ProfileService) :: any
local Types = require(ReplicatedStorage.Shared.Types)
local Constants = require(ReplicatedStorage.Shared.Constants)

local function createDefaultData(): Types.PlayerSaveData
	return {
		version = Constants.DATA_VERSION,
		currency = Constants.STARTING_CURRENCY,
		cupcake = 0,
		clickAccumulator = 0,
		quests = { completed = {}, progress = {} },
		lifetimeCookies = 0,
		upgrades = {},
		unlockedSkins = { "classic" },
		activeSkinId = "classic",
		lastLoginTime = 0,
		lastClaimTimestamp = 0,
		unlockedAchievements = {},
		prestigeCount = 0,
		ownedPasses = {},
		processedReceipts = {},
		settings = table.clone(Constants.DEFAULT_SETTINGS),
		stats = {
			totalClicks = 0,
			lifetimeCookies = 0,
			goldenCookiesCollected = 0,
			upgradesPurchasedTotal = 0,
			dailyStreak = 0,
		},
	}
end

-- The DataStore key is intentionally version-INDEPENDENT. Schema versioning lives INSIDE
-- the profile (data.version) and is handled by :Reconcile() plus any explicit migration
-- branch — NOT by the store name. Embedding DATA_VERSION in the key (the previous design)
-- meant the first version bump would point every returning player at a brand-new empty
-- store, orphaning their save: a latent mass-data-loss bug. Keep this key stable forever.
local PROFILE_STORE_NAME = "PlayerData"
local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, createDefaultData())

-- The one and only legacy store that ever shipped (when the key carried the version). Saves
-- made before this decouple live here; DataService.LoadProfile pulls each forward into the
-- new key exactly once. Hardcoded (not derived from DATA_VERSION) because "PlayerData_v1" is
-- the specific store that needs draining — a future bump must not change this target.
local LEGACY_STORE_NAME = "PlayerData_v1"
local LegacyProfileStore = ProfileService.GetProfileStore(LEGACY_STORE_NAME, createDefaultData())

-- True if a save holds real progress. Used to decide whether a legacy save is worth pulling
-- forward, and to guard against clobbering a new-key profile that already has data.
local function hasProgress(data: any): boolean
	if type(data) ~= "table" then return false end
	if (data.currency or 0) > 0 then return true end
	if (data.lifetimeCookies or 0) > 0 then return true end
	if (data.cupcake or 0) > 0 then return true end
	if (data.lastClaimTimestamp or 0) > 0 then return true end
	if data.upgrades and next(data.upgrades) ~= nil then return true end
	if data.unlockedAchievements and next(data.unlockedAchievements) ~= nil then return true end
	return false
end

-- One-time migration from the legacy versioned store to the new key. Runs at most once per
-- account: the `_migratedFromLegacy` flag (persisted in the profile) prevents re-running. A
-- legacy-load FAILURE (Roblox outage) deliberately leaves the flag unset so migration is
-- retried next join rather than silently abandoning the old save. The flag lives only at
-- runtime (set on the `any`-typed Data), so it never needs a Types/default-table entry.
local function migrateLegacyProfile(profile: any, userId: number)
	if profile.Data._migratedFromLegacy then return end

	-- A new-key profile that already holds progress must not be overwritten; just mark it.
	if hasProgress(profile.Data) then
		profile.Data._migratedFromLegacy = true
		return
	end

	local legacy = LegacyProfileStore:LoadProfileAsync("Player_" .. userId)
	if legacy == nil then
		-- Couldn't read the legacy store (likely an outage). Leave the flag unset to retry.
		return
	end

	if hasProgress(legacy.Data) then
		-- Copy the legacy save forward IN PLACE (ProfileService requires mutating the same
		-- Data table, never reassigning it), then reconcile to backfill any newer fields.
		for k in pairs(profile.Data) do
			profile.Data[k] = nil
		end
		for k, v in pairs(legacy.Data) do
			profile.Data[k] = v
		end
		profile:Reconcile()
	end

	profile.Data._migratedFromLegacy = true
	legacy:Release()
end

local Profiles = {}

local DataService = {}

function DataService.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local getPlayerData = (Remotes :: any).GetPlayerData :: RemoteFunction
	getPlayerData.OnServerInvoke = function(player: Player)
		local data = DataService.GetProfileData(player)
		while data == nil do
			task.wait(0.1)
			if not player:IsDescendantOf(Players) then return nil end
			data = DataService.GetProfileData(player)
		end
		return data
	end

	-- Lightweight authoritative read for client reconcile (cookies + cupcakes) plus the
	-- resolved gamepass cookie multiplier. The multiplier is shipped here so the client's
	-- optimistic prediction matches what the server credits — the client must never recompute
	-- it from ownership (that would duplicate PlayerEffectsService, the SSoT). Lazy require to
	-- avoid a load-time cycle.
	local getBalance = (Remotes :: any).GetBalance :: RemoteFunction
	getBalance.OnServerInvoke = function(player: Player): { currency: number, cupcake: number, cookieMultiplier: number }
		local data = DataService.GetProfileData(player)
		if not data then
			return { currency = 0, cupcake = 0, cookieMultiplier = 1 }
		end
		local PlayerEffectsService = require(script.Parent.Parent.Systems.PlayerEffectsService)
		return {
			currency = data.currency,
			cupcake = data.cupcake,
			cookieMultiplier = PlayerEffectsService:GetMultiplier(player, "Cookie"),
		}
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.LoadProfile, player)
	end

	Players.PlayerAdded:Connect(DataService.LoadProfile)
	
	Players.PlayerRemoving:Connect(function(player: Player)
		local profile = Profiles[player]
		if profile ~= nil then
			profile:Release()
		end
	end)
end

function DataService.LoadProfile(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- Pull a pre-decouple save forward into the new key if one exists (one-time/account).
		migrateLegacyProfile(profile, player.UserId)

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Profile session locked by another server. Please rejoin.")
		end)
		
		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
			
			local Remotes = require(ReplicatedStorage.Shared.Remotes)
			Remotes.DataLoaded:FireClient(player)
		else
			profile:Release()
		end
	else
		player:Kick("Profile failed to load due to a Roblox data outage. Please rejoin.")
	end
end

function DataService.GetProfileData(player: Player): Types.PlayerSaveData?
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

function DataService.AddCurrency(player: Player, amount: number)
	local data = DataService.GetProfileData(player)
	if data then
		data.currency += amount
		local AchievementService = require(script.Parent.Parent.Systems.AchievementService)
		AchievementService.RecordStat(player, "lifetimeCookies", amount)
	end
end

function DataService.AddCupcake(player: Player, amount: number)
	local data = DataService.GetProfileData(player)
	if data then
		data.cupcake += amount
	end
end

function DataService.DeductCurrency(player: Player, amount: number): boolean
	local data = DataService.GetProfileData(player)
	if data and data.currency >= amount then
		data.currency -= amount
		return true
	end
	return false
end

function DataService.DeductCupcake(player: Player, amount: number): boolean
	local data = DataService.GetProfileData(player)
	if data and data.cupcake >= amount then
		data.cupcake -= amount
		return true
	end
	return false
end

function DataService.IsLoaded(player: Player): boolean
	return Profiles[player] ~= nil
end

return DataService
