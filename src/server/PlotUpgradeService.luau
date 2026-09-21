local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules:WaitForChild("PlotUpgradeConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))

local Service = {}
local started = false
local event
local lastRequest = {}
local capacityConnections = {}

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function publish(player)
	local plot = PlotService.GetPlot(player)
	local capacity = plot and plot:GetAttribute("SlotCapacity") or Config.Levels[1].Capacity
	local level = Config.GetLevel(capacity)
	local nextDefinition = level and Config.Levels[level + 1]
	player:SetAttribute("PlotCapacity", capacity)
	player:SetAttribute("PlotUpgradeNextCapacity", nextDefinition and nextDefinition.Capacity or 0)
	player:SetAttribute("PlotUpgradeCost", nextDefinition and nextDefinition.Cost or 0)
	player:SetAttribute("PlotUpgradeMaxed", nextDefinition == nil)
end

function Service.TryUpgrade(player)
	if player:GetAttribute("PlayerDataStatus") ~= "Ready" then
		player:SetAttribute("PlotUpgradeStatus", "DataNotReady")
		return false
	end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < 0.75 then return false end
	lastRequest[player] = now

	local plot = PlotService.GetPlot(player)
	if not plot or not PlotService.IsOwner(player, plot) then
		player:SetAttribute("PlotUpgradeStatus", "NoPlot")
		return false
	end
	local capacity = plot:GetAttribute("SlotCapacity")
	local level = Config.GetLevel(capacity)
	if not level then
		warn("[PlotUpgradeService] Invalid SlotCapacity on " .. plot:GetFullName() .. ": " .. tostring(capacity))
		player:SetAttribute("PlotUpgradeStatus", "InvalidCapacity")
		return false
	end
	local nextDefinition = Config.Levels[level + 1]
	if not nextDefinition then
		player:SetAttribute("PlotUpgradeStatus", "MaxLevel")
		publish(player)
		return false
	end
	local stats = player:FindFirstChild("Stats")
	local cash = stats and stats:FindFirstChild("Cash")
	if not cash or not cash:IsA("NumberValue") or not finite(cash.Value) then
		player:SetAttribute("PlotUpgradeStatus", "InvalidCash")
		return false
	end
	if cash.Value < nextDefinition.Cost then
		player:SetAttribute("PlotUpgradeStatus", "NotEnoughCash")
		return false
	end

	-- No yielding between the final validation, charge, and capacity update.
	cash.Value -= nextDefinition.Cost
	plot:SetAttribute("SlotCapacity", nextDefinition.Capacity)
	player:SetAttribute("PlotUpgradeStatus", "Purchased")
	publish(player)
	print(string.format("[PlotUpgradeService] %s upgraded plot to %d slots for $%d",
		player.Name, nextDefinition.Capacity, nextDefinition.Cost))
	return true
end

function Service.Start()
	if started then return end
	started = true
	PlotService.Start()
	event = ReplicatedStorage:FindFirstChild("PlotUpgradeEvent")
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = "PlotUpgradeEvent"
		event.Parent = ReplicatedStorage
	end
	assert(event:IsA("RemoteEvent"), "PlotUpgradeEvent must be a RemoteEvent")
	event.OnServerEvent:Connect(function(player) Service.TryUpgrade(player) end)
	local function added(player)
		player:SetAttribute("PlotUpgradeStatus", "Ready")
		task.defer(function()
			local deadline = os.clock() + 15
			while player.Parent == Players and not PlotService.GetPlot(player) and os.clock() < deadline do task.wait(0.1) end
			if player.Parent ~= Players then return end
			local plot = PlotService.GetPlot(player)
			if not plot then return end
			if capacityConnections[player] then capacityConnections[player]:Disconnect() end
			capacityConnections[player] = plot:GetAttributeChangedSignal("SlotCapacity"):Connect(function()
				if PlotService.IsOwner(player, plot) then publish(player) end
			end)
			publish(player)
		end)
	end
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		if capacityConnections[player] then capacityConnections[player]:Disconnect(); capacityConnections[player] = nil end
	end)
	for _, player in ipairs(Players:GetPlayers()) do added(player) end
	print("[PlotUpgradeService] Phase 19 service started.")
end

return Service
