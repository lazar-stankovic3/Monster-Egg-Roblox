local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotService = require(script.Parent:WaitForChild("PlotService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local EggInventoryService = require(script.Parent:WaitForChild("EggInventoryService"))
local HatchService = require(script.Parent:WaitForChild("HatchService"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local IndexService = require(script.Parent:WaitForChild("IndexService"))
local Placement = require(ReplicatedStorage.Modules:WaitForChild("EggPlacement"))

local Service = {}
local STORE_NAME = "MonsterEggPlayerData_v1"
local LEGACY_INDEX_STORE = "MonsterEggIndex_v1"
local AUTOSAVE_SECONDS = 60
local states = {}
local started = false
local store
local legacyStore

local eggFields = { "UID", "EggType", "EggName", "Biome", "Rarity", "Size", "Scale" }
local sizeRanks = { Tiny = 1, Normal = 2, Large = 3, Huge = 4, Titanic = 5 }

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function encodeCFrame(cf)
	return { cf:GetComponents() }
end

local function decodeCFrame(data)
	if type(data) ~= "table" or #data ~= 12 then return nil end
	for _, value in ipairs(data) do if not finite(value) then return nil end end
	return CFrame.new(table.unpack(data))
end

local function copyEggMetadata(model)
	local data = {}
	for _, field in ipairs(eggFields) do data[field] = model:GetAttribute(field) end
	return data
end

local function snapshotPlaced(player, plot)
	local eggs, monsters = {}, {}
	local folder = plot and plot:FindFirstChild("PlacedEggs")
	local place = plot and plot:FindFirstChild("Place")
	if not folder or not place then return eggs, monsters end
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart and model:GetAttribute("OwnerUserId") == player.UserId then
			local data = copyEggMetadata(model)
			local boundingFrame = model:GetBoundingBox()
			data.CFrame = encodeCFrame(place.CFrame:ToObjectSpace(boundingFrame))
			if model:GetAttribute("IsMonster") == true then
				data.MonsterId = model:GetAttribute("MonsterId")
				data.UID = model:GetAttribute("UID")
				table.insert(monsters, data)
			else
				data.PendingMonsterId = model:GetAttribute("PendingMonsterId")
				local deadline = model:GetAttribute("HatchEndsAt")
				data.HatchAt = os.time() + math.max(0, (tonumber(deadline) or workspace:GetServerTimeNow()) - workspace:GetServerTimeNow())
				table.insert(eggs, data)
			end
		end
	end
	return eggs, monsters
end

local function snapshot(player)
	local stats = player:FindFirstChild("Stats")
	local speed = stats and stats:FindFirstChild("Speed")
	local cash = stats and stats:FindFirstChild("Cash")
	local plot = PlotService.GetPlot(player)
	local eggs, monsters = snapshotPlaced(player, plot)
	return {
		Version = 1,
		Stats = {
			Speed = speed and finite(speed.Value) and math.max(0, speed.Value) or 0,
			Cash = cash and finite(cash.Value) and math.max(0, cash.Value) or 1000,
		},
		OwnedTreadmill = TreadmillService.GetLevel(player),
		SlotCapacity = plot and plot:GetAttribute("SlotCapacity") or 6,
		EggInventory = EggInventoryService.Snapshot(player),
		PlacedEggs = eggs,
		Monsters = monsters,
		IndexUnlocks = IndexService.Export(player),
		SavedAt = os.time(),
	}
end

local function validData(data)
	return data == nil or (type(data) == "table" and data.Version == 1
		and type(data.Stats) == "table" and type(data.EggInventory) == "table"
		and type(data.PlacedEggs) == "table" and type(data.Monsters) == "table"
		and type(data.IndexUnlocks) == "table")
end

local function retry(callback)
	local ok, result
	for attempt = 1, 3 do
		ok, result = pcall(callback)
		if ok then return true, result end
		if attempt < 3 then task.wait(attempt * 2) end
	end
	return false, result
end

local function restorePlaced(player, plot, data)
	local folder = plot:FindFirstChild("PlacedEggs")
	local place = plot:FindFirstChild("Place")
	if not folder or not place then return end
	local seen = {}
	for index, saved in ipairs(data.Monsters) do
		if index > 100 then break end
		local relative = decodeCFrame(saved.CFrame)
		if relative and type(saved.MonsterId) == "string" and type(saved.UID) == "string" and not seen[saved.UID] then
			seen[saved.UID] = true
			local metadata = Instance.new("Folder")
			for _, field in ipairs(eggFields) do metadata:SetAttribute(field, saved[field]) end
			metadata:SetAttribute("OwnerUserId", player.UserId)
			local ok, monster = pcall(MonsterService.Create, metadata, saved.MonsterId)
			metadata:Destroy()
			if ok then
				monster.Name = saved.UID
				monster:SetAttribute("UID", saved.UID)
				monster:SetAttribute("OwnerUserId", player.UserId)
				monster:SetAttribute("HatchedAt", os.time())
				Placement.Move(monster, place.CFrame * relative)
				monster.Parent = folder
				MonsterService.AddLabel(monster)
			else warn("[PlayerDataService] Monster restore skipped: " .. tostring(monster)) end
		end
	end
	for index, saved in ipairs(data.PlacedEggs) do
		if index > 100 then break end
		local relative = decodeCFrame(saved.CFrame)
		if relative and type(saved.UID) == "string" and not seen[saved.UID] then
			seen[saved.UID] = true
			local egg = EggInventoryService.CreatePlacedVisual(player, saved)
			if egg then
				Placement.Move(egg, place.CFrame * relative)
				local prepared = HatchService.Prepare(egg, saved.PendingMonsterId)
				if prepared then
					egg.Parent = folder
					HatchService.Begin(egg, plot, prepared, math.max(0, (tonumber(saved.HatchAt) or os.time()) - os.time()))
				else egg:Destroy() end
			end
		end
	end
end

local function apply(player, data)
	local stats = player:WaitForChild("Stats", 15)
	local inventory = player:WaitForChild("EggInventory", 15)
	local deadline = os.clock() + 15
	local plot = PlotService.GetPlot(player)
	while not plot and player.Parent == Players and os.clock() < deadline do task.wait(0.1); plot = PlotService.GetPlot(player) end
	if not stats or not inventory or not plot then error("Player runtime objects were not ready") end
	local speed, cash = stats:FindFirstChild("Speed"), stats:FindFirstChild("Cash")
	if speed and finite(data.Stats.Speed) then speed.Value = math.max(0, data.Stats.Speed) end
	if cash and finite(data.Stats.Cash) then cash.Value = math.max(0, data.Stats.Cash) end
	local capacity = tonumber(data.SlotCapacity)
	if capacity and capacity % 1 == 0 and capacity >= 6 and capacity <= 100 then plot:SetAttribute("SlotCapacity", capacity) end
	TreadmillService.SetLevel(player, tonumber(data.OwnedTreadmill) or 1)
	EggInventoryService.Restore(player, inventory, data.EggInventory)
	IndexService.Import(player, data.IndexUnlocks)
	restorePlaced(player, plot, data)
end

local function loadPlayer(player)
	if states[player] then return end
	local state = { loaded = false, saving = false }
	states[player] = state
	player:SetAttribute("PlayerDataStatus", "Loading")
	player:SetAttribute("IndexDataStatus", "Loading")
	local ok, data = retry(function() return store:GetAsync("u_" .. player.UserId) end)
	if not ok or not validData(data) then
		player:SetAttribute("PlayerDataStatus", "LoadFailed")
		player:SetAttribute("IndexDataStatus", "LoadFailed")
		warn("[PlayerDataService] Load failed; saving disabled for " .. player.Name .. ": " .. tostring(data))
		return
	end
	if data == nil then
		data = { Version = 1, Stats = { Speed = 0, Cash = 1000 }, OwnedTreadmill = 1, SlotCapacity = 6,
			EggInventory = {}, PlacedEggs = {}, Monsters = {}, IndexUnlocks = {} }
		local legacyOk, legacy = retry(function() return legacyStore:GetAsync("u_" .. player.UserId) end)
		if not legacyOk then
			player:SetAttribute("PlayerDataStatus", "LoadFailed")
			player:SetAttribute("IndexDataStatus", "LoadFailed")
			warn("[PlayerDataService] Legacy Index migration read failed; saving disabled for " .. player.Name)
			return
		end
		if legacy ~= nil then
			if type(legacy) ~= "table" or legacy.Version ~= 1 or type(legacy.Unlocks) ~= "table" then
				player:SetAttribute("PlayerDataStatus", "LoadFailed")
				player:SetAttribute("IndexDataStatus", "LoadFailed")
				warn("[PlayerDataService] Unsupported legacy Index data; refusing migration for " .. player.Name)
				return
			end
			data.IndexUnlocks = legacy.Unlocks
		end
	end
	local applied, applyError = pcall(apply, player, data)
	if states[player] ~= state then return end
	if not applied then
		player:SetAttribute("PlayerDataStatus", "LoadFailed")
		player:SetAttribute("IndexDataStatus", "LoadFailed")
		warn("[PlayerDataService] Restore failed; saving disabled for " .. player.Name .. ": " .. tostring(applyError))
		return
	end
	state.loaded = true
	player:SetAttribute("PlayerDataStatus", "Ready")
	player:SetAttribute("IndexDataStatus", "Ready")
end

local function savePlayer(player, state, preparedSnapshot)
	if not state or not state.loaded or state.saving then return end
	state.saving = true
	local data = preparedSnapshot or snapshot(player)
	local ok, result = retry(function()
		return store:UpdateAsync("u_" .. player.UserId, function(old)
			if old ~= nil and not validData(old) then error("Unsupported player data; refusing overwrite") end
			if old and type(old.IndexUnlocks) == "table" then
				for id, size in pairs(old.IndexUnlocks) do
					if sizeRanks[size] and (not sizeRanks[data.IndexUnlocks[id]] or sizeRanks[size] > sizeRanks[data.IndexUnlocks[id]]) then
						data.IndexUnlocks[id] = size
					end
				end
			end
			return data
		end)
	end)
	state.saving = false
	if ok then
		if player.Parent == Players then
			IndexService.Import(player, result.IndexUnlocks)
			player:SetAttribute("PlayerDataStatus", "Ready")
			player:SetAttribute("IndexDataStatus", "Ready")
		end
	else
		if player.Parent == Players then player:SetAttribute("PlayerDataStatus", "SaveFailed"); player:SetAttribute("IndexDataStatus", "SaveFailed") end
		warn("[PlayerDataService] Save failed for " .. player.Name .. ": " .. tostring(result))
	end
end

local function flush(player, preparedSnapshot)
	local state = states[player]
	if not state then return end
	local deadline = os.clock() + 24
	while state.saving and os.clock() < deadline do task.wait(0.1) end
	savePlayer(player, state, preparedSnapshot)
end

function Service.Start()
	if started then return end
	started = true
	PlotService.Start()
	TreadmillService.Start()
	HatchService.Start()
	IndexService.Start()
	store = DataStoreService:GetDataStore(STORE_NAME)
	legacyStore = DataStoreService:GetDataStore(LEGACY_INDEX_STORE)
	Players.PlayerAdded:Connect(function(player) task.spawn(loadPlayer, player) end)
	Players.PlayerRemoving:Connect(function(player)
		-- Capture before other services' deferred cleanup, even if an autosave is in flight.
		local preparedSnapshot = states[player] and states[player].loaded and snapshot(player) or nil
		flush(player, preparedSnapshot)
		states[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, state in pairs(states) do task.spawn(savePlayer, player, state) end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player, state in pairs(states) do
			local preparedSnapshot = state.loaded and snapshot(player) or nil
			pending += 1
			task.spawn(function() flush(player, preparedSnapshot); pending -= 1 end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
end

return Service
