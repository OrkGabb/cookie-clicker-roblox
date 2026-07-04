--!strict
local ClickerInput = {}
export type ClickerInput = {
	lastClick:     number,
	cooldown:      number,
	sessionClicks: number,
	totalClicks:   number,
}
function ClickerInput.new(cooldown: number): ClickerInput
	return {
		lastClick     = 0,
		cooldown      = cooldown,
		sessionClicks = 0,
		totalClicks   = 0,
	}
end
return ClickerInput
