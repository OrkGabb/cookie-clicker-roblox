--!strict
local DataService = require(script.Parent.Services.DataService)
local MonetizationService = require(script.Parent.Services.MonetizationService)
local ValidationSystem = require(script.Parent.Systems.ValidationSystem)
local PurchaseSystem = require(script.Parent.Systems.PurchaseSystem)
local GoldenCookieService = require(script.Parent.Systems.GoldenCookieService)

print("Booting Server Architecture...")

-- 1. Init Services
DataService.Init()
MonetizationService.Init()

local SettingsService = require(script.Parent.Systems.SettingsService)
local AchievementService = require(script.Parent.Systems.AchievementService)
local DailyRewardService = require(script.Parent.Systems.DailyRewardService)
local ServerPassiveSystem = require(script.Parent.Systems.ServerPassiveSystem)
local QuestService = require(script.Parent.Systems.QuestService)
local ShopService = require(script.Parent.Systems.ShopService)
local PlayerEffectsService = require(script.Parent.Systems.PlayerEffectsService)

-- 2. Init Systems
-- Effects first: economy systems read gamepass multipliers from it, and its join
-- handler must be connected before ProcessClicks / passive accrual run for a player.
PlayerEffectsService.Init()
ValidationSystem.Init()
PurchaseSystem.Init()
GoldenCookieService.Init()
SettingsService.Init()
AchievementService.Init()
DailyRewardService.Init()
ServerPassiveSystem.Init()
QuestService.Init()
ShopService.Init()

print("Server Booted Successfully.")
