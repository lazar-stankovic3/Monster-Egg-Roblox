local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules:WaitForChild("HatchConfig"))
local Placement = require(ReplicatedStorage.Modules:WaitForChild("EggPlacement"))
local MonsterService = require(script.Parent:WaitForChild("MonsterService"))
local IndexService = require(script.Parent:WaitForChild("IndexService"))
local Players = game:GetService("Players")
local Service = {}
local active = {}
local random = Random.new()
local started = false

-- Prepare before consuming inventory. Failure leaves the equipped egg untouched.
function Service.Prepare(egg, savedMonsterId)
	local duration = Config.Timers[egg:GetAttribute("Rarity")]
	local monsterId = savedMonsterId or Config.Roll(egg:GetAttribute("EggType"), random)
	if not duration or not monsterId then return nil end
	local ok, monster = pcall(MonsterService.Create, egg, monsterId)
	if not ok then warn("[HatchService] " .. tostring(monster)); return nil end
	return { monster = monster, duration = duration }
end

function Service.Begin(egg, plot, prepared, remainingDuration)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HatchCountdown"
	gui.Size = UDim2.fromOffset(180, 45)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Adornee = egg.PrimaryPart
	local frame, size = egg:GetBoundingBox()
	gui.StudsOffsetWorldSpace = frame.Position - egg.PrimaryPart.Position + Vector3.new(0, size.Y / 2 + 1.5, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	local duration = math.max(0, tonumber(remainingDuration) or prepared.duration)
	label.Text = "Hatching: " .. math.ceil(duration) .. "s"
	label.Parent = gui
	gui.Parent = egg
	local deadline = workspace:GetServerTimeNow() + duration
	egg:SetAttribute("HatchEndsAt", deadline)
	egg:SetAttribute("HatchState", "Incubating")
	prepared.plot, prepared.deadline, prepared.label = plot, deadline, label
	prepared.owner = egg:GetAttribute("OwnerUserId")
	egg:SetAttribute("PendingMonsterId", prepared.monster:GetAttribute("MonsterId"))
	active[egg] = prepared
end

function Service.Start()
	if started then return end
	started = true
	IndexService.Start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then return end
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		for egg, entry in pairs(active) do
			local plot = entry.plot
			if not plot:IsDescendantOf(workspace) or egg.Parent ~= plot:FindFirstChild("PlacedEggs")
				or plot:GetAttribute("OwnerUserId") ~= entry.owner then
				entry.monster:Destroy()
				active[egg] = nil
			elseif now >= entry.deadline then
				local frame, size = egg:GetBoundingBox()
				local _, monsterSize = entry.monster:GetBoundingBox()
				local target = frame * CFrame.new(0, (monsterSize.Y - size.Y) / 2, 0)
				Placement.Move(entry.monster, target)
				entry.monster:SetAttribute("HatchedAt", now)
				local gui = entry.label.Parent
				gui.Name = "MonsterLabel"
				gui.Adornee = entry.monster.PrimaryPart
				gui.StudsOffsetWorldSpace = target.Position - entry.monster.PrimaryPart.Position
					+ Vector3.new(0, monsterSize.Y / 2 + 1.5, 0)
				gui.Size = UDim2.fromOffset(230, 75)
                entry.label.Text = string.format("%s\n%s | %s\n$%g/sec", entry.monster:GetAttribute("MonsterName"), entry.monster:GetAttribute("Rarity"), entry.monster:GetAttribute("Size"), entry.monster:GetAttribute("FinalIncome"))
				gui.Parent = entry.monster
				-- Keep one occupied entry in PlacedEggs; monsters count toward the same six-place limit.
				active[egg] = nil
				entry.monster.Parent = egg.Parent
				egg:Destroy()
				local owner = Players:GetPlayerByUserId(entry.owner)
				if owner then IndexService.RecordHatch(owner, entry.monster) end
			else
				local remaining = math.ceil(entry.deadline - now)
				if entry.remaining ~= remaining then
					entry.remaining = remaining
					entry.label.Text = "Hatching: " .. remaining .. "s"
				end
			end
		end
	end)
end

return Service
