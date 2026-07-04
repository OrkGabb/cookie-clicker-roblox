--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)

local ValidationSystem = {}

-- Authoritative click pipeline. Single entry point for BOTH the batched client clicks
-- and the Auto-Clicker gamepass (PlayerEffectsService calls this with clickCount = 1),
-- so simulated clicks inherit the exact same validation, CPK accrual, and multipliers.
function ValidationSystem.ProcessClicks(player: Player, clickCount: number)
	if typeof(clickCount) ~= "number" then return end

	local data = DataService.GetProfileData(player)
	if not data then return end

	-- Validate CPS against maximum theoretical rate (20 clicks per 0.5s batch buffer = 15-20 clicks max)
	local maxClicksPerBatch = 20
	if clickCount > maxClicksPerBatch then
		clickCount = maxClicksPerBatch
	end

	-- Gamepass multipliers are resolved centrally (OCP) and default to 1.0 for non-owners.
	local PlayerEffectsService = require(script.Parent.PlayerEffectsService)
	local cookieMult = PlayerEffectsService:GetMultiplier(player, "Cookie")

	local liveCPC = require(ReplicatedStorage.Shared.Util.EconomyMath).ComputeLiveCPC(data)
	local AchievementService = require(script.Parent.AchievementService)
	local totalAward = liveCPC * clickCount * cookieMult
	DataService.AddCurrency(player, totalAward)
	AchievementService.RecordStat(player, "totalClicks", clickCount)

	-- Cupcake gain (6.2): +1 cupcake per CLICKS_PER_CUPCAKE manual clicks. A plain running
	-- click tally (clickAccumulator) replaces the old cupcakesAwarded-vs-totalClicks delta
	-- tracking: add this batch's clicks, mint one cupcake per full CLICKS_PER_CUPCAKE, and
	-- carry the remainder. No prediction or stale-read surface — the cupcake balance is a
	-- concrete integer. The cupcake multiplier scales the minted amount (×2 / ×4 stacked,
	-- always whole integers — no rounding), not the click ratio.
	local CupcakeConfig = require(ReplicatedStorage.Shared.Config.CupcakeConfig)
	data.clickAccumulator += clickCount
	local gained = math.floor(data.clickAccumulator / CupcakeConfig.CLICKS_PER_CUPCAKE)
	if gained > 0 then
		local cupcakeMult = PlayerEffectsService:GetMultiplier(player, "Cupcake")
		data.cupcake += gained * cupcakeMult
		data.clickAccumulator = data.clickAccumulator % CupcakeConfig.CLICKS_PER_CUPCAKE
	end

	-- Quests: clicks + peak-currency checks (7c).
	require(script.Parent.QuestService).Evaluate(player)
end

function ValidationSystem.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	-- Assumes BatchedClicks is added to Remotes.luau
	local batchedClicksRemote = (Remotes :: any).BatchedClicks :: RemoteEvent

	batchedClicksRemote.OnServerEvent:Connect(function(player: Player, clickCount: number)
		-- Throttle the click remote. The legit client batches once per 0.5s (~2 calls/s,
		-- ClickSystem.luau), so a 20-calls-per-1s window leaves wide headroom for network
		-- jitter and burst delivery while a tight-loop spammer (dozens+/s sustained) is still
		-- dropped. The Auto-Clicker calls ValidationSystem.ProcessClicks directly and never
		-- goes through this remote, so it is unaffected by this limit.
		if not RateLimiter.Check(player, "BatchedClicks", 20, 1) then
			return
		end
		ValidationSystem.ProcessClicks(player, clickCount)
	end)
end

return ValidationSystem
