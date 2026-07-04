--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local Types = require(ReplicatedStorage.Shared.Types)

local SettingsService = {}

function SettingsService.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local UpdateSettings = (Remotes :: any).UpdateSettings :: RemoteEvent

	UpdateSettings.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then return end
		local data = DataService.GetProfileData(player)
		if not data then return end

		local newSettings = data.settings
		
		if type(payload.masterVolume) == "number" then
			newSettings.masterVolume = math.clamp(payload.masterVolume, 0, 100)
		end
		if type(payload.musicVolume) == "number" then
			newSettings.musicVolume = math.clamp(payload.musicVolume, 0, 100)
		end
		if type(payload.sfxVolume) == "number" then
			newSettings.sfxVolume = math.clamp(payload.sfxVolume, 0, 100)
		end
		if type(payload.performanceMode) == "boolean" then
			newSettings.performanceMode = payload.performanceMode
		end
		if type(payload.notifications) == "boolean" then
			newSettings.notifications = payload.notifications
		end
		-- Auto-Clicker on/off. Server-authoritative gating still lives in
		-- PlayerEffectsService (the loop only exists for real owners), so accepting this
		-- boolean from a non-owner is inert — there is no loop for it to control.
		if type(payload.autoClickerEnabled) == "boolean" then
			newSettings.autoClickerEnabled = payload.autoClickerEnabled
		end

		data.settings = newSettings
	end)

	-- NOTE: the Settings panel's "Reset Settings" applies DEFAULT_SETTINGS client-side and
	-- persists through UpdateSettings above (settings-only writes), so no separate
	-- settings-reset remote is needed here. There is deliberately NO destructive
	-- full-profile reset remote: a wipe capability must never be reachable by a live
	-- client. If QA ever needs one, use a local Studio command-bar script instead.
end

return SettingsService
