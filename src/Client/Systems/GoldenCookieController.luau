--!strict
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local Declare = require(script.Parent.Parent.UI.Declare)
local GoldenCookieConfig = require(ReplicatedStorage.Shared.Config.GoldenCookieConfig)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)

local GoldenCookieController = {}

type VFXService = {
	SpawnFeedback: (any, {
		text: string,
		icon: string?,
		duration: number?,
		holdTime: number?,
		curve: Enum.EasingStyle?,
		basePosition: UDim2?,
		textColor: Color3?,
		strokeColor: Color3?,
		textSize: number?
	}) -> ()
}

function GoldenCookieController.Init(vfxSystem: VFXService)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local spawnRemote = (Remotes :: any).SpawnGoldenCookie :: RemoteEvent
	local claimRemote = (Remotes :: any).ClaimGoldenCookie :: RemoteFunction
	
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local containerGui = Instance.new("ScreenGui")
	containerGui.Name = "GoldenCookieGui"
	containerGui.IgnoreGuiInset = true
	containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Sibling ScreenGuis at the same DisplayOrder render in undefined order; MainGui (0)
	-- has a full-screen opaque Background frame, so a default-order container is painted
	-- underneath it. Sit above MainGui (0) but below VFXSystem's "+N" popups (100).
	containerGui.DisplayOrder = 50
	-- Not a StarterGui clone, so a ResetOnSpawn destroy on respawn would never come back.
	containerGui.ResetOnSpawn = false
	
	-- Respects safe area so cookie doesn't fall behind mobile notches or TV edges
	containerGui.ClipToDeviceSafeArea = true
	containerGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
	containerGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	containerGui.Parent = playerGui

	-- Only one cookie on screen at a time: a new spawn replaces any still-descending one.
	local activeCookie: Instance? = nil

	spawnRemote.OnClientEvent:Connect(function(guid: string)
		-- Constrain between Sidebar (0.08) and ShopPanel (0.30)
		local randomX = math.random(15, 65) / 100

		if activeCookie then
			activeCookie:Destroy()
			activeCookie = nil
		end

		local btn = Declare.New("ImageButton")({
			Name = "GoldenCookie",
			Size = UDim2.fromScale(0.12, 0.12),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(randomX, -0.2),
			BackgroundTransparency = 1,
			Image = AssetIds.Golden_Cookie,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 50,
			Children = {
				Declare.UIAspectRatioConstraint({ AspectRatio = 1 })
			}
		})
		
		btn.Parent = containerGui
		activeCookie = btn

		local tInfo = TweenInfo.new(GoldenCookieConfig.DescentDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		local tween = TweenService:Create(btn, tInfo, {
			Position = UDim2.fromScale(randomX, 1.2)
		})
		
		local isClaimed = false
		
		btn.MouseButton1Click:Connect(function()
			if isClaimed then return end
			isClaimed = true

			local currentPos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
			btn:Destroy()
			if activeCookie == btn then activeCookie = nil end

			local result = claimRemote:InvokeServer(guid)
			if type(result) == "table" and type(result.amount) == "number" then
				-- Bigger text for the rare high-value tiers so a Jackpot reads as special.
				local tier = result.tier
				local textSize = if tier == "Jackpot" then 44
					elseif tier == "Rare" then 36
					else 30
				vfxSystem:SpawnFeedback({
					text = "+" .. NumberFormat.Format(result.amount),
					icon = AssetIds.Golden_Cookie,
					-- Rare event (45–90s apart): hold the number at full opacity ~0.8s so it
					-- reads clearly across every tier, then fade over 1.0s (~1.8s total visible).
					holdTime = 0.8,
					duration = 1.0,
					curve = Enum.EasingStyle.Elastic,
					basePosition = UDim2.fromOffset(currentPos.X, currentPos.Y),
					-- Themed gold-on-cocoa so the number reads against the cream background
					-- (the default white per-click styling was illegible here).
					textColor = Theme.Colors.Gold,
					strokeColor = Theme.Colors.Cocoa,
					textSize = textSize,
				})
			end
		end)
		
		tween.Completed:Connect(function()
			if btn.Parent then
				btn:Destroy()
			end
			if activeCookie == btn then activeCookie = nil end
		end)
		
		tween:Play()
	end)
end

return GoldenCookieController
