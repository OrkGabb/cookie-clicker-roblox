--!strict
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetIds = require(ReplicatedStorage.Shared.AssetIds)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local CookieSquish = require(script.Parent.Parent.UI.CookieSquish)

local SCATTER = 30   -- px spread around the cookie center
local FLOAT_RISE = 100 -- px the label travels upward

local VFXSystem = {}
VFXSystem.__index = VFXSystem

export type FeedbackConfig = {
	text: string,
	icon: string?,
	duration: number?,  -- fade-out length; total visible time is holdTime + duration
	holdTime: number?,  -- seconds held at full opacity BEFORE the fade starts (default 0)
	curve: Enum.EasingStyle?,
	basePosition: UDim2?, -- absolute screen position (golden cookie); omit for click scatter
	textColor: Color3?,   -- defaults to white (per-click "+N"); golden cookie themes it gold
	strokeColor: Color3?, -- defaults to black outline
	textSize: number?,    -- defaults to 28; bumped for high-tier golden rewards
}

type PoolEntry = {
	frame: Frame,
	icon: ImageLabel,
	label: TextLabel,
	stroke: UIStroke,
}

function VFXSystem.new(clickSystem: any, gameState: any)
	local self = setmetatable({}, VFXSystem) :: any

	self._gs = gameState
	self._clickSystem = clickSystem
	local player = Players.LocalPlayer
	self._playerGui = player:WaitForChild("PlayerGui")
	self._pool = {} :: { PoolEntry }

	-- Top-level layer for absolute-positioned feedback (golden cookie). High
	-- DisplayOrder keeps it above MainGui's opaque background. Click "+N" feedback
	-- does NOT use this layer — it parents into the live ClickerArea instead.
	self._screenLayer = Instance.new("ScreenGui")
	self._screenLayer.Name = "ClickVFXGui"
	self._screenLayer.IgnoreGuiInset = true
	self._screenLayer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenLayer.DisplayOrder = 100
	self._screenLayer.Parent = self._playerGui

	clickSystem.Clicked:Connect(function(gain: number)
		-- Real effect for Performance Mode: skip the per-click floating "+N" VFX,
		-- the heaviest per-click cost. Golden-cookie feedback is unaffected.
		if self._gs and self._gs:GetSettings().performanceMode then return end
		self:SpawnFeedback({
			text = "+" .. NumberFormat.Format(gain),
			icon = AssetIds.CookieMini,
			duration = 0.8,
			curve = Enum.EasingStyle.Quad,
		})
	end)

	return self
end

-- Replays the manual-click VISUAL feedback for one server-side Auto-Clicker tick. Reuses
-- the exact same paths a real click drives — no parallel VFX: the floating "+N" comes from
-- firing the same Clicked signal (so it inherits the Performance Mode skip) and the squish
-- from the shared CookieSquish SSoT. The "+N" value is GetPerClick (base click value),
-- identical to what a manual click shows.
--
-- The click sound is intentionally NOT played here: at 4 ticks/sec the repeated "crack"
-- is fatiguing (a frequency problem, not loudness). Manual clicks still play it via
-- ClickSystem:RegisterClick, where it's sporadic and player-intentional.
function VFXSystem:PlayAutoClickFeedback()
	if self._clickSystem then
		self._clickSystem.Clicked:Fire(self._gs:GetPerClick())
	end
	local button = self:_resolveContainer()
	if button then
		CookieSquish.Pulse(button)
	end
end

-- The live cookie button. MainGui is rebuilt by UISystem:Render, so we resolve it
-- fresh each spawn rather than caching a (potentially destroyed) reference.
function VFXSystem:_resolveContainer(): Instance?
	local gui = self._playerGui:FindFirstChild("MainGui")
	if not gui then return nil end
	local clickerConstraint = gui:FindFirstChild("ClickerConstraint")
	if not clickerConstraint then return nil end
	return clickerConstraint:FindFirstChild("TreatButton")
end

function VFXSystem:_buildEntry(): PoolEntry
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(0, 120, 0, 40)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.LayoutOrder = 1
	icon.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Font = Theme.Fonts.Display
	label.TextSize = 28
	label.TextColor3 = Color3.new(1, 1, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.LayoutOrder = 2

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = frame

	return { frame = frame, icon = icon, label = label, stroke = stroke }
end

function VFXSystem:_acquire(): PoolEntry
	local entry = table.remove(self._pool)
	if entry then return entry end
	return self:_buildEntry()
end

function VFXSystem:_release(entry: PoolEntry)
	-- If the container (MainGui) was destroyed mid-flight the frame is destroyed too,
	-- and re-parenting throws; drop such entries instead of pooling a dead instance.
	local ok = pcall(function()
		entry.frame.Parent = nil
	end)
	if ok then
		table.insert(self._pool, entry)
	end
end

function VFXSystem:SpawnFeedback(config: FeedbackConfig)
	-- Resolve the destination first; the scatter path needs the live cookie button.
	local parent: Instance
	local startPos: UDim2
	if config.basePosition then
		-- Absolute screen position on the top-level layer (golden cookie).
		parent = self._screenLayer
		startPos = config.basePosition
	else
		local container = self:_resolveContainer()
		if not container then return end
		parent = container
		-- Scatter around the cookie center so rapid clicks don't overlap.
		startPos = UDim2.new(0.5, math.random(-SCATTER, SCATTER), 0.5, math.random(-SCATTER, SCATTER))
	end

	local entry = self:_acquire()

	-- Reset visual state (pooled instances carry over from prior use). Color/size must
	-- be reset every spawn too, or a themed golden-cookie entry would bleed into a
	-- later reused per-click popup.
	entry.label.Text = config.text
	entry.label.TextTransparency = 0
	entry.label.TextColor3 = config.textColor or Color3.new(1, 1, 1)
	entry.label.TextSize = config.textSize or 28
	entry.stroke.Transparency = 0
	entry.stroke.Color = config.strokeColor or Color3.new(0, 0, 0)
	if config.icon then
		entry.icon.Visible = true
		entry.icon.Image = config.icon
		entry.icon.ImageTransparency = 0
	else
		entry.icon.Visible = false
	end

	entry.frame.Position = startPos
	entry.frame.Parent = parent

	local fadeDuration = config.duration or 0.8
	local holdTime = config.holdTime or 0
	local curve = config.curve or Enum.EasingStyle.Quad
	-- Total visible window: the label floats the whole time, but its transparency holds at
	-- full opacity for holdTime, then fades over fadeDuration. holdTime defaults to 0, so the
	-- per-click "+N" popup is unchanged; the golden-cookie reward passes a hold so the rare
	-- number is readable before it fades (a continuous fade-from-0 was too quick to read).
	local totalTime = holdTime + fadeDuration
	local moveInfo = TweenInfo.new(totalTime, curve, Enum.EasingDirection.Out)
	-- DelayTime on the fade keeps the label opaque during the hold; a plain Quad fade reads
	-- cleaner than overshooting curves on transparency.
	local fadeInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, holdTime)

	local endPos = startPos + UDim2.fromOffset(0, -FLOAT_RISE)
	local frameTween = TweenService:Create(entry.frame, moveInfo, { Position = endPos })
	TweenService:Create(entry.label, fadeInfo, { TextTransparency = 1 }):Play()
	TweenService:Create(entry.stroke, fadeInfo, { Transparency = 1 }):Play()
	if config.icon then
		TweenService:Create(entry.icon, fadeInfo, { ImageTransparency = 1 }):Play()
	end

	frameTween.Completed:Connect(function()
		self:_release(entry)
	end)
	frameTween:Play()
end

function VFXSystem:Init() end
function VFXSystem:Update(dt: number) end
function VFXSystem:Destroy()
	for _, entry in ipairs(self._pool) do
		entry.frame:Destroy()
	end
	self._pool = {}
	self._screenLayer:Destroy()
end

return VFXSystem
