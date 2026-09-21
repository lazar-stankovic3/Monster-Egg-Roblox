--!strict

local Formatter = {}

local suffixes = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg",
}

local function trim(text: string): string
	text = string.gsub(text, "(%..-)0+$", "%1")
	return string.gsub(text, "%.$", "")
end

function Formatter.Format(value: unknown): string
	local number = tonumber(value)
	if not number or number ~= number then return "0" end
	if number == math.huge then return "∞" end
	if number == -math.huge then return "-∞" end
	local absolute = math.abs(number)
	if absolute < 1000 then
		if number == math.floor(number) then return string.format("%.0f", number) end
		return trim(string.format("%.1f", number))
	end

	local group = math.floor(math.log10(absolute) / 3)
	if group >= #suffixes then return string.format("%.2e", number) end
	local scaled = number / (10 ^ (group * 3))
	local formatted
	if math.abs(scaled) >= 100 then
		formatted = string.format("%.0f", scaled)
	elseif math.abs(scaled) >= 10 then
		formatted = string.format("%.1f", scaled)
	else
		formatted = string.format("%.2f", scaled)
	end
	return trim(formatted) .. suffixes[group + 1]
end

return Formatter
