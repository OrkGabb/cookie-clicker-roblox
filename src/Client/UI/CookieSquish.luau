--!strict
-- Single source of truth for the cookie press/squish animation. Both the manual click
-- path (ClickerArea's MouseButton1 Down/Up) and the Auto-Clicker per-tick feedback
-- (VFXSystem:PlayAutoClickFeedback) drive the cookie squish through here, so the tween
-- shape lives in exactly one place (DRY) — no parallel animation code.
local TweenService = game:GetService("TweenService")

local CookieSquish = {}

local REST_SIZE = UDim2.fromScale(1.0, 1.0)
local PRESS_SIZE = UDim2.fromScale(0.92, 0.92)
local PRESS_INFO = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

-- Squish in (pointer down / hold start).
function CookieSquish.Press(btn: Instance)
	TweenService:Create(btn, PRESS_INFO, { Size = PRESS_SIZE }):Play()
end

-- Bounce back to rest (pointer up / hold end).
function CookieSquish.Release(btn: Instance)
	TweenService:Create(btn, RELEASE_INFO, { Size = REST_SIZE }):Play()
end

-- One self-contained press+release, for input-less triggers (Auto-Clicker tick) that
-- have no separate down/up events to bracket the squish.
function CookieSquish.Pulse(btn: Instance)
	CookieSquish.Press(btn)
	task.delay(0.05, function()
		CookieSquish.Release(btn)
	end)
end

return CookieSquish
