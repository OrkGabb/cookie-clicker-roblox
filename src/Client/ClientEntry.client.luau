--!strict
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(ReplicatedStorage.Shared.State.GameState)
local World = require(ReplicatedStorage.Shared.ECS.World)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ClickSystem = require(script.Parent.Systems.ClickSystem)
local VFXSystem = require(script.Parent.Systems.VFXSystem)
local UISystem = require(script.Parent.Systems.UISystem)
local GoldenCookieController = require(script.Parent.Systems.GoldenCookieController)
local PassiveSystem = require(ReplicatedStorage.Shared.ECS.Systems.PassiveSystem)
local SoundController = require(ReplicatedStorage.Shared.Util.SoundController)

print("Booting Client Architecture...")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

local getPlayerData = (Remotes :: any).GetPlayerData :: RemoteFunction
local savedData = getPlayerData:InvokeServer()

local state = GameState.new()
if savedData then
	state:LoadFromSave(savedData)
end

state:RecalculateStats()

-- Apply the player's saved volume preferences, then start the lofi background cycler.
SoundController.ApplyVolumes(state:GetSettings())
SoundController.PlayBackgroundMusic()

-- 3. Initialize ECS Systems
local clickSys = ClickSystem.new(state)
local vfxSys = VFXSystem.new(clickSys, state)
local uiSys = UISystem.new(state, clickSys)

GoldenCookieController.Init(vfxSys)
local passiveSys = PassiveSystem.new(state)

-- Auto-Clicker per-tick feedback: the server credits auto-clicks with no RemoteEvent of
-- its own, so the client has no trigger for the click VFX. Each tick the server pings the
-- owner here; replay the same "+N" popup, cookie squish, and sound a manual click shows.
local AutoClickTick = (Remotes :: any).AutoClickTick :: RemoteEvent
AutoClickTick.OnClientEvent:Connect(function()
	vfxSys:PlayAutoClickFeedback()
end)

-- 4. Boot ECS World (binds systems to RenderStepped)
local world = World.new({
	clickSys,
	vfxSys,
	uiSys,
	passiveSys
})

-- 5. Periodic reconcile: client passive income is optimistic prediction; the server
-- is the source of truth. Pull the authoritative balance and hard-set it to squash
-- accumulated drift, so the purchase gate and server agree.
local Constants = require(ReplicatedStorage.Shared.Constants)
local getBalance = (Remotes :: any).GetBalance :: RemoteFunction

-- Pull the server-authoritative balance AND the resolved gamepass cookie multiplier, then
-- apply both. The multiplier feeds the client's optimistic prediction so the "+N" popup and
-- running total reflect what the server actually credits (e.g. ×2 with Cookie Power) instead
-- of the un-multiplied base. Resolved server-side (PlayerEffectsService) — never recomputed here.
local function pullAuthoritative()
	local ok, authoritative = pcall(function()
		return getBalance:InvokeServer()
	end)
	if not ok or type(authoritative) ~= "table" then return end
	if type(authoritative.cookieMultiplier) == "number" then
		state:ApplyPassMultiplier(authoritative.cookieMultiplier)
	end
	-- Catch the optimistic display UP to the server only — never pull it DOWN. Clicks credit
	-- locally the instant they happen, while the server lags by up to the 0.5s batch window +
	-- round-trip, so a hard-set to a momentarily-behind server total is exactly what made the
	-- counter jump backward (5 -> 4 -> 6) under fast clicking. The server still catches up within
	-- a batch, so the display converges upward without ever reverting. Spends decrease the display
	-- directly via Deduct* (applied only after the server confirms the purchase), so suppressing
	-- downward reconcile can never strand a spend at a stale-high value.
	if type(authoritative.currency) == "number"
		and authoritative.currency > state:GetCurrency() then
		state:SetCurrency(authoritative.currency)
	end
	if type(authoritative.cupcake) == "number"
		and authoritative.cupcake > state:GetCupcake() then
		state:SetCupcake(authoritative.cupcake)
	end
end

-- Seed once at boot so even the very first click predicts the correct (multiplied) amount,
-- then keep reconciling on the periodic tick.
pullAuthoritative()
task.spawn(function()
	while true do
		task.wait(Constants.BALANCE_RECONCILE_INTERVAL)
		pullAuthoritative()
	end
end)

print("Client Booted Successfully.")
