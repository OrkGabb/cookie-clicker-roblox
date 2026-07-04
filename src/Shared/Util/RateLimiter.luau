--!strict
local RateLimiter = {}

local limits: { [Player]: { [string]: { calls: number, resetTime: number } } } = {}

function RateLimiter.Check(player: Player, action: string, maxCalls: number, windowSecs: number): boolean
	local now = os.clock()
	
	if not limits[player] then
		limits[player] = {}
	end
	
	local playerLimits = limits[player]
	if not playerLimits[action] then
		playerLimits[action] = { calls = 0, resetTime = now + windowSecs }
	end
	
	local record = playerLimits[action]
	
	if now >= record.resetTime then
		record.calls = 0
		record.resetTime = now + windowSecs
	end
	
	if record.calls >= maxCalls then
		return false
	end
	
	record.calls += 1
	return true
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	limits[player] = nil
end)

return RateLimiter
