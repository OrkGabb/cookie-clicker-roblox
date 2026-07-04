--!strict
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(ReplicatedStorage.Shared.State.GameState)
local UpgradeConfig = require(ReplicatedStorage.Shared.Config.UpgradeConfig)
local SkinConfigModule = require(ReplicatedStorage.Shared.Config.SkinConfig)
local Constants = require(ReplicatedStorage.Shared.Constants)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local EconomyMath = require(ReplicatedStorage.Shared.Util.EconomyMath)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local MainGui = require(script.Parent.Parent.UI.MainGui)
local WindowPanel = require(script.Parent.Parent.UI.Components.WindowPanel)
local Declare = require(script.Parent.Parent.UI.Declare)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local UISystem = {}
UISystem.__index = UISystem

function UISystem.new(state: GameState.GameState, clickSystem: any)
	local self = setmetatable({}, UISystem) :: any
	self._gs = state
	self._clickSystem = clickSystem
	self._guiInstance = nil
	self._playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._activeWindow = nil
	self._activeWindowState = "Main"
	self._toastQueue = {}
	self._isShowingToast = false
	self._affordCache = {}
	return self
end

function UISystem:Init()
	self:Render()
	
	-- StatsChanged is an in-place refresh, NOT a full rebuild: a full Render on every
	-- purchase destroys the upgrade button mid-hold and breaks fast-buy (Item 5a), and
	-- snaps the shop scroll to top (Item 3a). SkinChanged still does a full rebuild.
	self._gs.StatsChanged:Connect(function() self:_refreshStats() end)
	self._gs.SkinChanged:Connect(function() self:Render() end)
	
	self._gs.Changed:Connect(function()
		self:FastUpdateCurrency()
	end)
	
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local AchievementUnlocked = (Remotes :: any).AchievementUnlocked :: RemoteEvent
	AchievementUnlocked.OnClientEvent:Connect(function(achievementId: string)
		self:ShowToast(achievementId)
	end)

	-- 7e: the deferred reward toast (fired ~2s after the unlock toast).
	local AchievementReward = (Remotes :: any).AchievementReward :: RemoteEvent
	AchievementReward.OnClientEvent:Connect(function(achievementId: string, rewardType: string, amount: number)
		local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
		if rewardType == "Currency" then
			-- Server already credited; mirror optimistically so the balance matches.
			if type(amount) == "number" then
				self._gs:AddCurrency(amount)
			end
			self:QueueToast({
				header = "Reward!",
				title = "+" .. NumberFormat.Format(amount) .. " Cookies earned",
				icon = AssetIds.CookieMini,
				sound = "DailyClaim",
			})
		else
			self:QueueToast({
				header = "Reward!",
				title = "New skin unlocked!",
				icon = AssetIds.Achievements,
				sound = "DailyClaim",
			})
		end
	end)

	local QuestCompleted = (Remotes :: any).QuestCompleted :: RemoteEvent
	QuestCompleted.OnClientEvent:Connect(function(questId: string, reward: number)
		-- Server already credited; mirror optimistically so the TopBar updates now.
		if type(reward) == "number" then
			self._gs:SetCupcake(self._gs:GetCupcake() + reward)
		end
		local QuestConfig = require(ReplicatedStorage.Shared.Config.QuestConfig)
		local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
		local title = questId
		for _, q in ipairs(QuestConfig) do
			if q.id == questId then title = q.name break end
		end
		self:QueueToast({
			header = "Quest Complete!",
			title = title .. "  +" .. tostring(reward) .. " Cupcakes",
			icon = AssetIds.Cupcake,
			sound = "AchievementUnlock",
		})
	end)
	
	-- Shop grant: server already credited; pull the authoritative balance immediately
	-- (don't wait for the reconcile tick) and confirm with a toast.
	local ShopPurchaseGranted = (Remotes :: any).ShopPurchaseGranted :: RemoteEvent
	ShopPurchaseGranted.OnClientEvent:Connect(function(_productId: number)
		local getBalance = (Remotes :: any).GetBalance :: RemoteFunction
		local ok, authoritative = pcall(function()
			return getBalance:InvokeServer()
		end)
		if ok and type(authoritative) == "table" then
			-- A just-purchased Cookie pass changes the multiplier; apply it so prediction
			-- (popup / total / CpS) updates immediately without waiting for a reconcile tick.
			if type(authoritative.cookieMultiplier) == "number" then
				self._gs:ApplyPassMultiplier(authoritative.cookieMultiplier)
			end
			-- Catch up to the granted balance, but upward-only: this sync can land mid-fast-click
			-- when the server is momentarily behind the optimistic total, and a hard-set would
			-- yank the counter backward. (Same rule as the reconcile loop in ClientEntry.)
			if type(authoritative.currency) == "number"
				and authoritative.currency > self._gs:GetCurrency() then
				self._gs:SetCurrency(authoritative.currency)
			end
			if type(authoritative.cupcake) == "number"
				and authoritative.cupcake > self._gs:GetCupcake() then
				self._gs:SetCupcake(authoritative.cupcake)
			end
		end
		local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
		self:QueueToast({
			header = "Purchase Complete!",
			title = "Thanks for your support!",
			icon = AssetIds.Shop,
			sound = "DailyClaim",
		})
	end)

	GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(function()
		self:Render()
	end)
end

function UISystem:SetState(newState: string)
	if self._activeWindowState == newState then return end
	
	if self._activeWindow then
		self._activeWindow:Destroy()
		self._activeWindow = nil
	end
	
	self._activeWindowState = newState
	
	if newState == "Main" then
		return
	end
	
	local content = {}
	if newState == "Shop" then
		local ShopPanel = require(script.Parent.Parent.UI.Panels.ShopPanel)
		self._activeWindow = ShopPanel({
			onClose = function()
				self:SetState("Main")
			end
		})
		if self._guiInstance then
			self._activeWindow.Parent = self._guiInstance
		end
		return
	elseif newState == "Settings" then
		local SettingsPanel = require(script.Parent.Parent.UI.Panels.SettingsPanel)
		self._activeWindow = SettingsPanel({
			settings = self._gs:GetSettings(),
			onUpdateSettings = function(newSettings)
				self._gs:UpdateSettings(newSettings)
			end,
			onClose = function()
				self:SetState("Main")
			end
		})
		if self._guiInstance then
			self._activeWindow.Parent = self._guiInstance
		end
		return
	elseif newState == "DailyReward" then
		local DailyRewardsPanel = require(script.Parent.Parent.UI.Panels.DailyRewardsPanel)
		self._activeWindow = DailyRewardsPanel({
			currentStreak = self._gs:GetStats().dailyStreak,
			canClaim = self._gs:CanClaimDaily(),
			onClaimAction = function()
				local claimDailyReward = (Remotes :: any).ClaimDailyReward :: RemoteFunction
				local result = claimDailyReward:InvokeServer()
				if result.success then
					-- Server already credited the profile; mirror it into the optimistic
					-- client state so the currency actually appears (Item 2).
					if result.rewardAmount and result.rewardAmount > 0 then
						self._gs:AddCurrency(result.rewardAmount)
					end
					self._gs:UpdateDailyState(result.newStreak, result.newTimestamp)

					local DailyRewardConfig = require(ReplicatedStorage.Shared.Config.DailyRewardConfig)
					local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
					local streak = result.newStreak
					local dayIndex = if streak == 0 then 1 else ((streak - 1) % 7) + 1
					local claimedDef = nil
					for _, d in ipairs(DailyRewardConfig) do
						if d.day == dayIndex then claimedDef = d break end
					end
					if claimedDef then
						self:QueueToast({
							header = "Daily Reward!",
							title = "+" .. NumberFormat.Format(claimedDef.rewardAmount) .. " Cookies",
							icon = AssetIds.DailyReward,
							sound = "DailyClaim",
						})
					end

					-- Force a panel rebuild: SetState early-returns if the target state
					-- equals the current one, so bounce through Main first.
					self._activeWindowState = "Main"
					self:SetState("DailyReward")
				end
			end,
			onClose = function()
				self:SetState("Main")
			end
		})
		if self._guiInstance then
			self._activeWindow.Parent = self._guiInstance
		end
		return
	elseif newState == "Quests" then
		local QuestPanel = require(script.Parent.Parent.UI.Panels.QuestPanel)
		local getQuests = (Remotes :: any).GetQuests :: RemoteFunction
		local questState = getQuests:InvokeServer()
		-- The open request may have been superseded while InvokeServer yielded.
		if self._activeWindowState ~= "Quests" then return end
		self._activeWindow = QuestPanel({
			completed = questState.completed or {},
			progress = questState.progress or {},
			-- Achievements is now a tab inside the Quests panel.
			stats = self._gs:GetStats(),
			hasAchievement = function(id) return self._gs:HasAchievement(id) end,
			onClose = function()
				self:SetState("Main")
			end
		})
		if self._guiInstance then
			self._activeWindow.Parent = self._guiInstance
		end
		return
	end
end

function UISystem:Render()
	-- Preserve shop scroll position across the destroy/rebuild (Item 3a): a purchase
	-- fires StatsChanged -> full Render, which otherwise snaps the list back to top.
	local savedScroll: Vector2? = nil
	if self._guiInstance then
		local oldShop = self._guiInstance:FindFirstChild("ShopPanel") :: ScrollingFrame?
		if oldShop then savedScroll = oldShop.CanvasPosition end
		self._guiInstance:Destroy()
	end

	local activeSkinDef = SkinConfigModule.SkinMap[self._gs:GetActiveSkinId()] or SkinConfigModule.Default
	
	local gui = MainGui({
		currency = self._gs:GetCurrency(),
		cupcake = self._gs:GetCupcake(),
		perSecond = self._gs:GetPerSecond(),
		activeSkinDef = activeSkinDef,
		upgrades = UpgradeConfig,
		upgradeCounts = self._gs.Upgrades.counts,
		onClickTreat = function()
			self._clickSystem:RegisterClick()
		end,
		onBuyUpgrade = function(id)
			local def = nil
			for _, u in ipairs(UpgradeConfig) do
				if u.id == id then def = u break end
			end
			if not def then return end
			
			local currentCount = self._gs.Upgrades.counts[id] or 0
			if def.maxStacks and currentCount >= def.maxStacks then return end

			local cost = EconomyMath.ComputeUpgradeCost(def, currentCount)
			if self._gs:GetCurrency() < cost then return end

			local cupcakeCost = EconomyMath.ComputeMilestoneCupcakeCost(id, currentCount + 1)
			if cupcakeCost > 0 and self._gs:GetCupcake() < cupcakeCost then return end

			local requestPurchase = (Remotes :: any).RequestPurchase :: RemoteFunction
			local success = requestPurchase:InvokeServer(id)
			if success then
				self._gs:DeductCurrency(cost)
				if cupcakeCost > 0 then self._gs:DeductCupcake(cupcakeCost) end
				self._gs:RecordPurchase(def)
			end
		end,
		onShop = function() self:SetState("Shop") end,
		onSettings = function() self:SetState("Settings") end,
		onDailyReward = function() self:SetState("DailyReward") end,
		onQuests = function() self:SetState("Quests") end,
	})
	
	self._guiInstance = gui
	self._affordCache = {}
	gui.Parent = self._playerGui

	if savedScroll then
		local newShop = gui:FindFirstChild("ShopPanel") :: ScrollingFrame?
		if newShop then newShop.CanvasPosition = savedScroll end
	end

	if self._activeWindowState ~= "Main" then
		local cachedState = self._activeWindowState
		self._activeWindowState = "Main"
		self:SetState(cachedState)
	end
end

function UISystem:FastUpdateCurrency()
	if not self._guiInstance then return end
	
	local topBar = self._guiInstance:FindFirstChild("TopBar")
	if topBar then
		local container = topBar:FindFirstChild("CurrencyContainer")
		if container then
			local display = container:FindFirstChild("CurrencyDisplay") :: TextLabel
			if display then
				display.Text = NumberFormat.Format(self._gs:GetCurrency())
			end
		end
		local cupcakeContainer = topBar:FindFirstChild("CupcakeContainer")
		if cupcakeContainer then
			local cupDisplay = cupcakeContainer:FindFirstChild("CupcakeDisplay") :: TextLabel?
			if cupDisplay then
				cupDisplay.Text = NumberFormat.Format(self._gs:GetCupcake())
			end
		end
	end

	self:_refreshUpgradeAffordability()
end

-- In-place refresh for StatsChanged: updates passive rate + per-upgrade count/cost
-- text without destroying the GUI, so a held fast-buy button survives and the shop
-- scroll position is preserved.
function UISystem:_refreshStats()
	if not self._guiInstance then return end

	local topBar = self._guiInstance:FindFirstChild("TopBar")
	if topBar then
		local passive = topBar:FindFirstChild("PassiveDisplay") :: TextLabel?
		if passive then
			passive.Text = "+" .. NumberFormat.Rate(self._gs:GetPerSecond(), "/s")
		end
	end

	local shopPanel = self._guiInstance:FindFirstChild("ShopPanel")
	if shopPanel then
		for _, def in ipairs(UpgradeConfig) do
			local button = shopPanel:FindFirstChild("Upgrade_" .. def.id)
			if button then
				local count = self._gs.Upgrades.counts[def.id] or 0
				local cost = EconomyMath.ComputeUpgradeCost(def, count)
				local maxed = def.maxStacks ~= nil and count >= def.maxStacks
				local cupcakeCost = EconomyMath.ComputeMilestoneCupcakeCost(def.id, count + 1)

				button:SetAttribute("Maxed", maxed)

				local infoContainer = button:FindFirstChild("InfoContainer")
				if infoContainer then
					local titleContainer = infoContainer:FindFirstChild("TitleContainer")
					if titleContainer then
						local title = titleContainer:FindFirstChild("Title") :: TextLabel?
						if title then
							title.Text = def.name .. " (x" .. count .. ")"
						end
					end
					local costContainer = infoContainer:FindFirstChild("CostContainer")
					if costContainer then
						local costText = costContainer:FindFirstChild("CostText") :: TextLabel?
						if costText then
							costText.Text = maxed and "Maxed" or ("Cost: " .. NumberFormat.Format(cost))
						end
						local costIcon = costContainer:FindFirstChild("CostIcon") :: ImageLabel?
						if costIcon then
							costIcon.Visible = not maxed
						end
						local cupText = costContainer:FindFirstChild("CupcakeCostText") :: TextLabel?
						if cupText then
							cupText.Text = "+ " .. NumberFormat.Format(cupcakeCost)
							cupText.Visible = cupcakeCost > 0 and not maxed
						end
						local cupIcon = costContainer:FindFirstChild("CupcakeCostIcon") :: ImageLabel?
						if cupIcon then
							cupIcon.Visible = cupcakeCost > 0 and not maxed
						end
					end
				end
			end
		end
	end

	-- Costs changed, so affordability must be re-evaluated from scratch.
	self._affordCache = {}
	self:_refreshUpgradeAffordability()
end

function UISystem:_refreshUpgradeAffordability()
	if not self._guiInstance then return end
	local shopPanel = self._guiInstance:FindFirstChild("ShopPanel")
	if not shopPanel then return end
	
	local currency = self._gs:GetCurrency()
	for _, def in ipairs(UpgradeConfig) do
		local button = shopPanel:FindFirstChild("Upgrade_" .. def.id)
		if button then
			local count = self._gs.Upgrades.counts[def.id] or 0
			local cost = EconomyMath.ComputeUpgradeCost(def, count)
			local maxed = def.maxStacks ~= nil and count >= def.maxStacks
			local cupcakeCost = EconomyMath.ComputeMilestoneCupcakeCost(def.id, count + 1)
			local canAffordCupcake = cupcakeCost == 0 or self._gs:GetCupcake() >= cupcakeCost
			local canAfford = currency >= cost and canAffordCupcake and not maxed

			-- Only push when affordability actually flips. The button owns its own
			-- background/hover/press state (Item 5b) and reacts to this attribute, so
			-- we never stomp the transient pressed-tint on every Changed tick (Item 2).
			if self._affordCache[def.id] == canAfford then
				continue
			end
			self._affordCache[def.id] = canAfford

			button:SetAttribute("Affordable", canAfford)

			local infoContainer = button:FindFirstChild("InfoContainer")
			if infoContainer then
				local titleContainer = infoContainer:FindFirstChild("TitleContainer")
				if titleContainer then
					local title = titleContainer:FindFirstChild("Title") :: TextLabel?
					if title then
						title.TextColor3 = canAfford and Theme.Colors.TextPrimary or Theme.Colors.TextMuted
					end
					local effect = titleContainer:FindFirstChild("Effect") :: TextLabel?
					if effect then
						effect.TextColor3 = canAfford and Theme.Colors.TextPrimary or Theme.Colors.TextMuted
					end
				end
				local costContainer = infoContainer:FindFirstChild("CostContainer")
				if costContainer then
					local costText = costContainer:FindFirstChild("CostText") :: TextLabel?
					if costText then
						costText.TextColor3 = canAfford and Theme.Colors.Gold or Theme.Colors.TextMuted
					end
				end
			end
		end
	end
end

function UISystem:Update(dt: number) end
function UISystem:Destroy()
	if self._guiInstance then
		self._guiInstance:Destroy()
	end
	if self._activeWindow then
		self._activeWindow:Destroy()
	end
end

function UISystem:ShowToast(achievementId: string)
	local AchievementConfig = require(ReplicatedStorage.Shared.Config.AchievementConfig)
	local def = nil
	for _, c in ipairs(AchievementConfig) do
		if c.id == achievementId then def = c break end
	end
	if not def then return end
	self:QueueToast({
		header = "Achievement Unlocked!",
		title = def.title,
		icon = def.icon,
		sound = "AchievementUnlock",
	})
end

function UISystem:QueueToast(payload: { header: string, title: string, icon: string, sound: string? })
	-- Real effect for the Notifications setting: suppress all toasts when off.
	if not self._gs:GetSettings().notifications then return end
	table.insert(self._toastQueue, payload)
	self:_processToastQueue()
end

function UISystem:_processToastQueue()
	if self._isShowingToast or #self._toastQueue == 0 then return end
	if not self._guiInstance then return end
	
	self._isShowingToast = true
	local payload = table.remove(self._toastQueue, 1)
	
	if payload.sound then
		local SoundController = require(ReplicatedStorage.Shared.Util.SoundController)
		SoundController.Play(payload.sound)
	end
	
	local toast = Declare.Frame({
		Size = UDim2.new(0, 300, 0, 80),
		Position = UDim2.new(0.5, 0, 0, -100),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Colors.HeaderPink,
		Parent = self._guiInstance,
		ZIndex = 100,
		Children = {
			Declare.UICorner({ CornerRadius = Theme.Corners.Standard }),
			Declare.UIStroke({ Color = Theme.Colors.Cocoa, Thickness = 2 }),
			Declare.UIPadding({ PaddingTop = Theme.Padding.Standard, PaddingBottom = Theme.Padding.Standard, PaddingLeft = Theme.Padding.Standard, PaddingRight = Theme.Padding.Standard }),
			Declare.UIListLayout({ FillDirection = Enum.FillDirection.Horizontal, Padding = Theme.Padding.Standard, VerticalAlignment = Enum.VerticalAlignment.Center }),
			Declare.New("ImageLabel")({
				Size = UDim2.new(0, 50, 0, 50),
				BackgroundTransparency = 1,
				Image = payload.icon,
				ScaleType = Enum.ScaleType.Fit,
			}),
			Declare.Frame({
				Size = UDim2.new(1, -60, 1, 0),
				BackgroundTransparency = 1,
				Children = {
					Declare.UIListLayout({ SortOrder = Enum.SortOrder.LayoutOrder }),
					Declare.TextLabel({
						Size = UDim2.new(1, 0, 0, 24),
						BackgroundTransparency = 1,
						Text = payload.header,
						Font = Theme.Fonts.Display,
						TextSize = 18,
						TextColor3 = Theme.Colors.TextPrimary,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Declare.TextLabel({
						Size = UDim2.new(1, 0, 1, -24),
						BackgroundTransparency = 1,
						Text = payload.title,
						Font = Theme.Fonts.Body,
						TextSize = 16,
						TextColor3 = Theme.Colors.TextPrimary,
						TextXAlignment = Enum.TextXAlignment.Left,
					})
				}
			})
		}
	})
	
	local ts = game:GetService("TweenService")
	ts:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 20) }):Play()
	task.delay(4, function()
		local t = ts:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -100) })
		t:Play()
		t.Completed:Connect(function() 
			toast:Destroy()
			self._isShowingToast = false
			self:_processToastQueue()
		end)
	end)
end

return UISystem
