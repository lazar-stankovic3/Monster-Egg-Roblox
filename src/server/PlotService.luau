local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlotService = {}
local STARTING_SLOTS = 6
local started = false
local plots = {}
local assignments = {}
local waiting = {}
local queued = {}

local function resetPlot(plot, ownerUserId)
	plot:SetAttribute("OwnerUserId", ownerUserId)
	plot:SetAttribute("SlotCapacity", STARTING_SLOTS)
	plot.PlacedEggs:ClearAllChildren()
end

local function preparePlot(plot)
	if not plot:IsA("Model") then return false end
	local place = plot:FindFirstChild("Place")
	if not place or not place:IsA("BasePart") or not place.Anchored then
		warn("[PlotService] " .. plot:GetFullName() .. " needs an anchored Place Part.")
		return false
	end
	local eggs = plot:FindFirstChild("PlacedEggs")
	if eggs and not eggs:IsA("Folder") then
		warn("[PlotService] PlacedEggs must be a Folder: " .. plot:GetFullName())
		return false
	end
	if not eggs then
		eggs = Instance.new("Folder")
		eggs.Name = "PlacedEggs"
		eggs.Parent = plot
	end
	resetPlot(plot, 0)
	return true
end

local function assignWaiting()
	for _, plot in ipairs(plots) do
		if plot:GetAttribute("OwnerUserId") ~= 0 then
			continue
		end
		while #waiting > 0 do
			local player = table.remove(waiting, 1)
			queued[player] = nil
			if player.Parent == Players and not assignments[player] then
				-- No yields between claiming the plot and recording its owner.
				resetPlot(plot, player.UserId)
				assignments[player] = plot
				player:SetAttribute("PlotName", plot.Name)
				player:SetAttribute("PlotStatus", "Assigned")
				break
			end
		end
	end
end

local function enqueue(player)
	if assignments[player] or queued[player] or player.Parent ~= Players then
		return
	end
	player:SetAttribute("PlotName", nil)
	player:SetAttribute("PlotStatus", "WaitingForPlot")
	queued[player] = true
	table.insert(waiting, player)
	assignWaiting()
end

function PlotService.GetPlot(player)
	return assignments[player]
end

function PlotService.IsOwner(player, plot)
	return plot ~= nil and assignments[player] == plot and plot:GetAttribute("OwnerUserId") == player.UserId
end

function PlotService.Start()
	if started then
		return
	end
	started = true
	local folder = Workspace:FindFirstChild("Plots")
	if not folder or not folder:IsA("Folder") then
		warn("[PlotService] Create Workspace.Plots (Folder) and plot Models; players will wait until plots are configured and the server is restarted.")
	else
		local candidates = folder:GetChildren()
		table.sort(candidates, function(a, b)
			return a.Name < b.Name
		end)
		local names = {}
		for _, plot in ipairs(candidates) do
			if names[plot.Name] then
				warn("[PlotService] Duplicate plot name skipped: " .. plot.Name)
			elseif preparePlot(plot) then
				names[plot.Name] = true
				table.insert(plots, plot)
			end
		end
	end
	Players.PlayerAdded:Connect(enqueue)
	Players.PlayerRemoving:Connect(function(player)
		queued[player] = nil
		for index = #waiting, 1, -1 do
			if waiting[index] == player then
				table.remove(waiting, index)
			end
		end
		local plot = assignments[player]
		assignments[player] = nil
		if plot then
			resetPlot(plot, 0)
		end
		player:SetAttribute("PlotName", nil)
		player:SetAttribute("PlotStatus", nil)
		assignWaiting()
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		enqueue(player)
	end
end

return PlotService

