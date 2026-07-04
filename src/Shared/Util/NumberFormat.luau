--!strict
local NumberFormat = {}
local SUFFIXES = { "", "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function NumberFormat.Format(n: number): string
	if n ~= n then return "0" end
	if n == math.huge or n == -math.huge then return "Max" end
	if n < 0 then n = 0 end
	
	if n < 1000 then
		return tostring(math.floor(n))
	end
	
	local mag = math.max(1, math.floor(math.log10(math.max(n, 1)) / 3))
	local scaled = n / (10 ^ (mag * 3))
	
	-- Prevent boundary rounding (e.g., 999,999 rounding to 1000.0k)
	if tonumber(string.format("%.1f", scaled)) >= 1000 then
		mag = mag + 1
		scaled = scaled / 1000
	end
	
	local suffix = SUFFIXES[mag + 1]
	if not suffix then
		mag = #SUFFIXES - 1
		suffix = SUFFIXES[mag + 1]
		scaled = n / (10 ^ (mag * 3))
	end
	
	return string.format("%.1f%s", scaled, suffix)
end

function NumberFormat.WithCommas(n: number): string
	if n ~= n then return "0" end
	if n == math.huge or n == -math.huge then return "Max" end
	if n < 0 then n = 0 end

	local s = tostring(math.floor(n))
	local result = ""
	local len = #s
	for i = 1, len do
		result = result .. s:sub(i, i)
		local rem = len - i
		if rem > 0 and rem % 3 == 0 then
			result = result .. ","
		end
	end
	return result
end

function NumberFormat.Rate(n: number, suffix: string): string
	return NumberFormat.Format(n) .. " " .. suffix
end

return NumberFormat
