local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Service = {}
local started = false

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function payTick()
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("PlayerDataStatus") == "Loading" then continue end
		local income = MonsterService.GetIncome(player)
		if not finite(income) or income < 0 then income = 0 end
		player:SetAttribute("CashPerSecond", income)
		local stats = player:FindFirstChild("Stats")
		local cash = stats and stats:FindFirstChild("Cash")
		if cash and cash:IsA("NumberValue") and finite(cash.Value) then
			local balance = cash.Value + income
			if income > 0 and finite(balance) then cash.Value = balance end
		end
	end
end

function Service.Start()
	if started then return end
	started = true
	PlotService.Start()
	local function added(player) player:SetAttribute("CashPerSecond", 0) end
	Players.PlayerAdded:Connect(added)
	for _, player in ipairs(Players:GetPlayers()) do added(player) end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 then return end
		-- One current-state payout per tick, no replay of missed ticks after a stall.
		elapsed %= 1
		payTick()
	end)
end

return Service
