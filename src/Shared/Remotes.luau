--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FOLDER_NAME = "GameRemotes"
local EVENT_NAMES = {
	"DataLoaded",
	"RequestSave",
	"SkinUnlocked",
	"AchievementUnlocked",
	"AchievementReward",
	"DailyRewardClaimed",
	"BatchedClicks",
	"SpawnGoldenCookie",
	"UpdateSettings",
	"QuestCompleted",
	"ShopPurchaseGranted",
	"AutoClickTick",   -- server -> owner: fires each Auto-Clicker tick to replay click VFX
}
local FUNCTION_NAMES = {
	"GetPlayerData",
	"ClaimDailyReward",
	"RequestPurchase",
	"ClaimGoldenCookie",
	"GetBalance",
	"GetQuests",
}
export type Remotes = {
	DataLoaded: RemoteEvent,
	RequestSave: RemoteEvent,
	SkinUnlocked: RemoteEvent,
	AchievementUnlocked: RemoteEvent,
	AchievementReward: RemoteEvent,
	DailyRewardClaimed: RemoteEvent,
	BatchedClicks: RemoteEvent,
	SpawnGoldenCookie: RemoteEvent,
	UpdateSettings: RemoteEvent,
	QuestCompleted: RemoteEvent,
	ShopPurchaseGranted: RemoteEvent,
	AutoClickTick: RemoteEvent,
	GetPlayerData: RemoteFunction,
	ClaimDailyReward: RemoteFunction,
	RequestPurchase: RemoteFunction,
	ClaimGoldenCookie: RemoteFunction,
	GetBalance: RemoteFunction,
	GetQuests: RemoteFunction,
}
local Remotes = {} :: Remotes
local RemotesAny: any = Remotes
if RunService:IsServer() then
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	for _, name in ipairs(EVENT_NAMES) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		RemotesAny[name] = event
	end
	for _, name in ipairs(FUNCTION_NAMES) do
		local func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = folder
		RemotesAny[name] = func
	end
else
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 10) :: Folder
	for _, name in ipairs(EVENT_NAMES) do
		RemotesAny[name] = folder:WaitForChild(name)
	end
	for _, name in ipairs(FUNCTION_NAMES) do
		RemotesAny[name] = folder:WaitForChild(name)
	end
end
return Remotes
