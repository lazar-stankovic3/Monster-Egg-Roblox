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
local MonsterConfig = require(ReplicatedStorage.Modules:WaitForChild("MonsterConfig"))
local PlotUpgradeConfig = require(ReplicatedStorage.Modules:WaitForChild("PlotUpgradeConfig"))

local Service = {}
local STORE_NAME = "MonsterEggPlayerData_v1"
local LEGACY_INDEX_STORE = "MonsterEggIndex_v1"
local AUTOSAVE_SECONDS = 60
local MAX_OFFLINE_SECONDS = 6 * 60 * 60
local states = {}
local started = false
local store
local legacyStore
local savePlayer

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

local function savedMonsterIncome(monsters)
	local total = 0
	local seen = {}
	if type(monsters) ~= "table" then return total end
	for index, monster in ipairs(monsters) do
		if index > 100 then break end
		local uid = monster.UID
		if type(uid) == "string" and uid ~= "" and not seen[uid] then
			seen[uid] = true
			local income = MonsterConfig.CalculateIncome(monster.MonsterId, monster.Rarity, monster.Size)
			if finite(income) and income > 0 then total += income end
		end
	end
	return total
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
		ProcessedReceipts = (states[player] and states[player].processedReceipts) or {},
		SavedAt = os.time(),
		-- This is the timestamp paired with the saved Cash/monster snapshot. Updating it
		-- on autosave also makes crash recovery bounded without replaying paid online time.
		LastLogoutTime = os.time(),
	}
end

local function validData(data)
	return data == nil or (type(data) == "table" and data.Version == 1
		and type(data.Stats) == "table" and type(data.EggInventory) == "table"
		and type(data.PlacedEggs) == "table" and type(data.Monsters) == "table"
		and type(data.IndexUnlocks) == "table"
		and (data.ProcessedReceipts == nil or type(data.ProcessedReceipts) == "table"))
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
	if capacity and PlotUpgradeConfig.GetLevel(capacity) then plot:SetAttribute("SlotCapacity", capacity) end
	TreadmillService.SetLevel(player, tonumber(data.OwnedTreadmill) or 1)
	EggInventoryService.Restore(player, inventory, data.EggInventory)
	IndexService.Import(player, data.IndexUnlocks)
	restorePlaced(player, plot, data)
end

local function loadPlayer(player)
	if states[player] then return end
	local state = { loaded = false, saving = false, closing = false, finalized = false }
	states[player] = state
	player:SetAttribute("PlayerDataStatus", "Loading")
	player:SetAttribute("IndexDataStatus", "Loading")
	player:SetAttribute("OfflineIncomeAmount", 0)
	player:SetAttribute("OfflineIncomeSeconds", 0)
	local offlineIncome, offlineSeconds = 0, 0
	local now = os.time()
	-- Claim offline income atomically. LastLogoutTime is advanced in the same write as
	-- Cash, so reconnects or overlapping servers cannot pay the same interval twice.
	local ok, data = retry(function()
		return store:UpdateAsync("u_" .. player.UserId, function(old)
			if old == nil then return nil end
			if not validData(old) then error("Unsupported player data; refusing offline claim") end
			local previous = tonumber(old.LastLogoutTime) or tonumber(old.SavedAt) or now
			local elapsed = math.clamp(math.floor(now - previous), 0, MAX_OFFLINE_SECONDS)
			local rate = savedMonsterIncome(old.Monsters)
			local earned = rate * elapsed
			if not finite(earned) or earned < 0 then earned = 0 end
			local cash = tonumber(old.Stats.Cash)
			if not finite(cash) or cash < 0 then cash = 0 end
			offlineIncome, offlineSeconds = earned, elapsed
			old.Stats.Cash = cash + earned
			old.LastLogoutTime = now
			old.SavedAt = now
			return old
		end)
	end)
	if not ok or not validData(data) then
		player:SetAttribute("PlayerDataStatus", "LoadFailed")
		player:SetAttribute("IndexDataStatus", "LoadFailed")
		warn("[PlayerDataService] Load failed; saving disabled for " .. player.Name .. ": " .. tostring(data))
		return
	end
	if data == nil then
		data = { Version = 1, Stats = { Speed = 0, Cash = 1000 }, OwnedTreadmill = 1, SlotCapacity = 6,
			EggInventory = {}, PlacedEggs = {}, Monsters = {}, IndexUnlocks = {},
			ProcessedReceipts = {},
			SavedAt = now, LastLogoutTime = now }
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
	state.processedReceipts = data.ProcessedReceipts or {}
	local applied, applyError = pcall(apply, player, data)
	if states[player] ~= state then return end
	if not applied then
		player:SetAttribute("PlayerDataStatus", "LoadFailed")
		player:SetAttribute("IndexDataStatus", "LoadFailed")
		warn("[PlayerDataService] Restore failed; saving disabled for " .. player.Name .. ": " .. tostring(applyError))
		return
	end
	state.loaded = true
	player:SetAttribute("LoadedMonsterCount", #data.Monsters)
	player:SetAttribute("OfflineIncomeAmount", offlineIncome)
	player:SetAttribute("OfflineIncomeSeconds", offlineSeconds)
	player:SetAttribute("PlayerDataStatus", "Ready")
	player:SetAttribute("IndexDataStatus", "Ready")
	print(string.format("[PlayerDataService] Loaded %s: %d egg(s), %d monster(s)",
		player.Name, #data.PlacedEggs, #data.Monsters))

	-- Persist plot mutations shortly after placement/hatch instead of relying on the
	-- next 60-second autosave or Studio shutdown. Hatch replaces an egg with a
	-- monster in two child events, so a short debounce captures the settled state.
	local plot = PlotService.GetPlot(player)
	local folder = plot and plot:FindFirstChild("PlacedEggs")
	if folder then
		state.plotConnections = {}
		local function changed()
			if states[player] ~= state or not state.loaded or state.closing then return end
			state.plotRevision = (state.plotRevision or 0) + 1
			local revision = state.plotRevision
			task.delay(1, function()
				if states[player] ~= state or state.closing or state.plotRevision ~= revision then return end
				while state.saving and states[player] == state and not state.closing do task.wait(0.1) end
				if states[player] == state and not state.closing and state.plotRevision == revision then
					savePlayer(player, state)
				end
			end)
		end
		table.insert(state.plotConnections, folder.ChildAdded:Connect(changed))
		table.insert(state.plotConnections, folder.ChildRemoved:Connect(changed))
		table.insert(state.plotConnections, plot:GetAttributeChangedSignal("SlotCapacity"):Connect(changed))
	end
end

savePlayer = function(player, state, preparedSnapshot)
	if not state or not state.loaded or state.saving
		or (state.closing and preparedSnapshot == nil) then return end
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
			if old and type(old.ProcessedReceipts) == "table" then
				data.ProcessedReceipts = data.ProcessedReceipts or {}
				for purchaseId, timestamp in pairs(old.ProcessedReceipts) do
					data.ProcessedReceipts[purchaseId] = timestamp
				end
			end
			return data
		end)
	end)
	state.saving = false
	if ok then
		player:SetAttribute("SavedMonsterCount", #data.Monsters)
		print(string.format("[PlayerDataService] Saved %s: %d inventory egg(s), %d placed egg(s), %d monster(s)",
			player.Name, #data.EggInventory, #data.PlacedEggs, #data.Monsters))
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

-- Atomically records the receipt in the same profile update that grants Cash/Speed.
-- A retried Roblox receipt therefore cannot grant the same product twice.
function Service.ProcessProductReceipt(player, purchaseId, grant)
	local state = states[player]
	if not state or not state.loaded or state.closing or player:GetAttribute("PlayerDataStatus") ~= "Ready" then
		return false
	end
	if type(purchaseId) ~= "string" or purchaseId == "" or type(grant) ~= "table" then return false end
	local statName = grant.Stat
	local amount = tonumber(grant.Amount)
	local minimum = tonumber(grant.Minimum)
	if statName ~= "Cash" and statName ~= "Speed" then return false end
	if amount and (not finite(amount) or amount <= 0) then return false end
	if minimum and (not finite(minimum) or minimum < 0) then return false end
	if not amount and not minimum then return false end

	local deadline = os.clock() + 20
	while state.saving and states[player] == state and os.clock() < deadline do task.wait(0.1) end
	if states[player] ~= state or state.saving or state.closing then return false end
	state.saving = true
	local newlyGranted = false
	local ok, result = retry(function()
		return store:UpdateAsync("u_" .. player.UserId, function(old)
			if not validData(old) or old == nil then error("Player profile is unavailable") end
			old.ProcessedReceipts = old.ProcessedReceipts or {}
			if old.ProcessedReceipts[purchaseId] ~= nil then
				newlyGranted = false
				return old
			end
			local current = tonumber(old.Stats[statName]) or 0
			if not finite(current) or current < 0 then current = 0 end
			old.Stats[statName] = if amount then current + amount else math.max(current, minimum)
			old.ProcessedReceipts[purchaseId] = os.time()
			newlyGranted = true
			return old
		end)
	end)
	state.saving = false
	if not ok or not result then
		warn("[PlayerDataService] Product receipt save failed: " .. tostring(result))
		return false
	end

	state.processedReceipts = result.ProcessedReceipts or state.processedReceipts or {}
	if newlyGranted then
		local stats = player:FindFirstChild("Stats")
		local value = stats and stats:FindFirstChild(statName)
		if not value or not value:IsA("NumberValue") then return false end
		if amount then value.Value += amount else value.Value = math.max(value.Value, minimum) end
		player:SetAttribute("LastShopPurchase", statName)
	end
	return true
end

local function finalizePlayer(player)
	local state = states[player]
	if not state then return end
	-- Capture exactly once, before PlotService's deferred cleanup can empty the plot.
	-- PlayerRemoving and BindToClose may run together in Studio; both must reuse this
	-- snapshot instead of allowing a later empty snapshot to overwrite it.
	state.closing = true
	state.finalSnapshot = state.finalSnapshot or (state.loaded and snapshot(player) or nil)
	if state.finalized then return end
	if state.finalizing then
		local deadline = os.clock() + 25
		while state.finalizing and os.clock() < deadline do task.wait(0.1) end
		return
	end
	state.finalizing = true
	local deadline = os.clock() + 24
	while state.saving and os.clock() < deadline do task.wait(0.1) end
	if not state.finalized then
		savePlayer(player, state, state.finalSnapshot)
		state.finalized = true
	end
	state.finalizing = false
end

function Service.Start()
	if started then return end
	started = true
	print("[PlayerDataService] Starting persistence service...")
	PlotService.Start()
	TreadmillService.Start()
	HatchService.Start()
	IndexService.Start()
	store = DataStoreService:GetDataStore(STORE_NAME)
	legacyStore = DataStoreService:GetDataStore(LEGACY_INDEX_STORE)
	print("[PlayerDataService] Persistence service started.")
	Players.PlayerAdded:Connect(function(player) task.spawn(loadPlayer, player) end)
	Players.PlayerRemoving:Connect(function(player)
		local state = states[player]
		finalizePlayer(player)
		if state and state.plotConnections then
			for _, connection in ipairs(state.plotConnections) do connection:Disconnect() end
		end
		states[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, state in pairs(states) do
				if not state.closing then task.spawn(savePlayer, player, state) end
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player in pairs(states) do
			pending += 1
			task.spawn(function() finalizePlayer(player); pending -= 1 end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
end

return Service
