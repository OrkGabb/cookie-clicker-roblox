--!strict
-- @author OrkGabb
-- SSoT for game audio: UI/click SFX, toast cues, and the background music cycler.
-- All one-shots route through the "SFX" SoundGroup and music through "Music", so the
-- Master/SFX/Music volume settings (see SoundController.ApplyVolumes) control everything.

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local SoundController = {}

-- One-shot effect ids. Empty entries are skipped safely at runtime.
local SOUND_IDS: { [string]: string } = {
	AchievementUnlock = "", -- TODO: celebratory chime
	DailyClaim = "",        -- TODO: reward / coin jingle
	Click = "rbxassetid://114928098062696", -- Cookie_Clicker_-_Eat_SFX
	UI = "rbxassetid://95154184427705",     -- suave button feedback
	Purchase = "rbxassetid://76523643207374", -- shop purchase confirm
}

-- Minimum seconds between click plays: only enough to dedupe a same-frame double-fire /
-- hardware overlap. Imperceptible to the player and does not throttle rapid/autoclicker
-- input (larger values audibly gate the sound on/off).
local CLICK_COOLDOWN = 0.02

-- Lofi background tracks. Cycled randomly, never repeating the same track twice in a row.
local MUSIC_TRACKS: { string } = {
	"rbxassetid://77135691581229",  -- Ambient Nature LoFi
	"rbxassetid://129338574094673", -- Rainy Day Lofi Ambience
	"rbxassetid://119338609842850", -- Spooky LoFi
}

local function getOrCreateGroup(name: string): SoundGroup
	local group = SoundService:FindFirstChild(name)
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end
	return group :: SoundGroup
end

-- Master is a real multiplier over the per-channel groups. Sounds route through SFX /
-- Music, so a standalone "Master" group would control nothing. Single source of truth
-- for volume; called at boot (ClientEntry) and on every Settings change.
function SoundController.ApplyVolumes(settings: Types.ClientSettings)
	local master = settings.masterVolume / 100
	getOrCreateGroup("SFX").Volume = master * (settings.sfxVolume / 100)
	getOrCreateGroup("Music").Volume = master * (settings.musicVolume / 100)
end

-- Plays a one-shot routed through the given SoundGroup. No-ops cleanly if id is unset.
local function playOneShot(id: string?, groupName: string)
	if not id or id == "" then return end

	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.SoundGroup = getOrCreateGroup(groupName)
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	-- Safety cleanup in case Ended never fires (bad/unresolved asset).
	task.delay(10, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Toast / named cues (AchievementUnlock, DailyClaim, ...).
function SoundController.Play(key: string)
	playOneShot(SOUND_IDS[key], "SFX")
end

-- Persistent, preloaded SFX instances. Reusing one instance per effect (instead of
-- Instance.new per call) means :Play() restarts a single tone — no overlap stacking —
-- and the asset is already resolved, so there's no fetch latency between press and sound.
local function makeCachedSfx(id: string): Sound?
	if not id or id == "" then return nil end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.SoundGroup = getOrCreateGroup("SFX")
	sound.Parent = SoundService
	return sound
end

local _clickSound = makeCachedSfx(SOUND_IDS.Click)
local _uiSound = makeCachedSfx(SOUND_IDS.UI)

task.spawn(function()
	local toLoad = {}
	if _clickSound then table.insert(toLoad, _clickSound) end
	if _uiSound then table.insert(toLoad, _uiSound) end
	pcall(function()
		ContentProvider:PreloadAsync(toLoad)
	end)
end)

local _lastClick = 0

function SoundController.PlayClickSound()
	if not _clickSound then return end
	local now = os.clock()
	if now - _lastClick < CLICK_COOLDOWN then return end
	_lastClick = now
	-- :Play() rewinds to the start, guaranteeing one clean tone per click.
	_clickSound:Play()
end

function SoundController.PlayUISound()
	if not _uiSound then return end
	-- No yield before :Play(); the cached, preloaded instance fires immediately.
	_uiSound:Play()
end

local _musicSound: Sound? = nil
local _currentTrack = 0
local _musicStarted = false

-- Starts the background music cycler (idempotent). Picks a random track, plays it once
-- (not looped, so Ended fires), then on Ended jumps to a *different* random track with no
-- silence gap. Volume follows the Music group via ApplyVolumes.
function SoundController.PlayBackgroundMusic()
	if _musicStarted then return end
	_musicStarted = true

	local sound = Instance.new("Sound")
	sound.Looped = false
	-- Full per-sound volume: the music level (default 60%) is owned by the musicVolume
	-- setting via the Music SoundGroup (ApplyVolumes), so there's no second attenuation here.
	sound.Volume = 1
	sound.SoundGroup = getOrCreateGroup("Music")
	sound.Parent = SoundService
	_musicSound = sound

	local function playTrack(index: number)
		_currentTrack = index
		sound.SoundId = MUSIC_TRACKS[index]
		sound:Play()
	end

	sound.Ended:Connect(function()
		local nextIndex = _currentTrack
		if #MUSIC_TRACKS > 1 then
			repeat
				nextIndex = math.random(1, #MUSIC_TRACKS)
			until nextIndex ~= _currentTrack
		end
		playTrack(nextIndex)
	end)

	playTrack(math.random(1, #MUSIC_TRACKS))
end

return SoundController
