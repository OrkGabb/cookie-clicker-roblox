--!strict
-- Server-authoritative quest tracking (7c). Progress is recomputed from authoritative
-- player data on each relevant event; completion awards CPK (cupcakes) and emits
-- QuestCompleted. Rewards are CPK-only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.Parent.Services.DataService)
local QuestConfig = require(ReplicatedStorage.Shared.Config.QuestConfig)
local Types = require(ReplicatedStorage.Shared.Types)

local QuestService = {}

local questCompletedRemote: RemoteEvent

local function ensureQuestState(data: Types.PlayerSaveData): Types.QuestState
	if not data.quests then
		data.quests = { completed = {}, progress = {} }
	end
	-- Defensive: older partial saves may have one half.
	if not data.quests.completed then data.quests.completed = {} end
	if not data.quests.progress then data.quests.progress = {} end
	return data.quests
end

local function uniqueUpgradeCount(data: Types.PlayerSaveData): number
	local n = 0
	for _, count in pairs(data.upgrades) do
		if count > 0 then n += 1 end
	end
	return n
end

local function computeProgress(quest: QuestConfig.QuestDefinition, data: Types.PlayerSaveData): number
	local quests = data.quests
	if quest.kind == "totalClicks" then
		return data.stats.totalClicks
	elseif quest.kind == "uniqueUpgrades" then
		return uniqueUpgradeCount(data)
	elseif quest.kind == "peakCurrency" then
		-- Monotonic peak: max of stored value and current balance.
		return math.max(quests.progress[quest.id] or 0, data.currency)
	elseif quest.kind == "passiveTicks" then
		-- Incremented externally by RecordPassiveTick; just read it back.
		return quests.progress[quest.id] or 0
	end
	return 0
end

function QuestService.Evaluate(player: Player)
	local data = DataService.GetProfileData(player)
	if not data then return end
	local quests = ensureQuestState(data)

	for _, quest in ipairs(QuestConfig) do
		if quests.completed[quest.id] then continue end

		local progress = computeProgress(quest, data)
		quests.progress[quest.id] = progress

		if progress >= quest.target then
			quests.completed[quest.id] = true
			data.cupcake += quest.reward
			questCompletedRemote:FireClient(player, quest.id, quest.reward)
		end
	end
end

-- Called once per server passive tick that credits the player.
function QuestService.RecordPassiveTick(player: Player)
	local data = DataService.GetProfileData(player)
	if not data then return end
	local quests = ensureQuestState(data)

	for _, quest in ipairs(QuestConfig) do
		if quest.kind == "passiveTicks" and not quests.completed[quest.id] then
			quests.progress[quest.id] = (quests.progress[quest.id] or 0) + 1
		end
	end

	QuestService.Evaluate(player)
end

function QuestService.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	questCompletedRemote = (Remotes :: any).QuestCompleted :: RemoteEvent

	local getQuests = (Remotes :: any).GetQuests :: RemoteFunction
	getQuests.OnServerInvoke = function(player: Player): Types.QuestState
		local data = DataService.GetProfileData(player)
		if not data then
			return { completed = {}, progress = {} }
		end
		-- Refresh derived progress so the panel reflects current state on open.
		QuestService.Evaluate(player)
		return ensureQuestState(data)
	end
end

return QuestService
