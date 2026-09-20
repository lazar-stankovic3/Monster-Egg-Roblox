local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Modules:WaitForChild("MonsterConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Service = {}

local function placeholder(definition)
	local model = Instance.new("Model")
	local function part(name, size, position, color, shape)
		local item = Instance.new("Part")
		item.Name, item.Size, item.Position, item.Color = name, size, position, color
		item.Shape = shape or Enum.PartType.Ball
		item.Anchored, item.CanCollide = true, false
		item.Material = Enum.Material.SmoothPlastic
		item.Parent = model
		return item
	end
	model.PrimaryPart = part("Body", Vector3.new(2, 1.8, 2), Vector3.new(0, 1, 0), definition.Color)
	for _, x in ipairs({-0.4, 0.4}) do
		part("Eye", Vector3.new(0.35, 0.45, 0.2), Vector3.new(x, 1.25, -0.9), Color3.new(1, 1, 1))
		part("Pupil", Vector3.new(0.14, 0.22, 0.12), Vector3.new(x, 1.25, -1.01), Color3.new(0, 0, 0))
	end
	if string.find(definition.MonsterName, "Bunny") then
		for _, x in ipairs({-0.45, 0.45}) do
			part("Ear", Vector3.new(0.4, 1.5, 0.5), Vector3.new(x, 2.2, 0), definition.Color)
		end
	elseif string.find(definition.MonsterName, "Dragon") then
		for _, x in ipairs({-1.1, 1.1}) do
			part("Wing", Vector3.new(0.6, 1.2, 1.3), Vector3.new(x, 1.2, 0.2), definition.Color, Enum.PartType.Block)
		end
	end
	model:SetAttribute("Placeholder", true)
	return model
end

function Service.Create(egg, monsterId)
	local definition = Config.Definitions[monsterId]
	local folder = ServerStorage:FindFirstChild("MonsterModels")
	local source = folder and folder:FindFirstChild(definition.ModelName)
	local model = source and source:IsA("Model") and source:Clone() or placeholder(definition)
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("LuaSourceContainer") or item:IsA("JointInstance") or item:IsA("Constraint")
			or item:IsA("BodyMover") or item:IsA("ProximityPrompt") then item:Destroy() end
	end
	local firstPart
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			firstPart = firstPart or item
			item.Anchored = true
			item.CanCollide, item.CanTouch, item.CanQuery = false, false, true
			item.AssemblyLinearVelocity, item.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		end
	end
	if not firstPart then model:Destroy(); error("Monster model has no BasePart: " .. definition.ModelName) end
	model.PrimaryPart = model.PrimaryPart or firstPart
	model:ScaleTo(egg:GetAttribute("Scale"))
	model:PivotTo(CFrame.new())
	-- Inherit the egg's size multiplier exactly; never shrink to its footprint.
	model.Name = HttpService:GenerateGUID(false)
	for _, name in ipairs({"EggType", "EggName", "Biome", "Rarity", "Size", "Scale", "OwnerUserId"}) do
		model:SetAttribute(name, egg:GetAttribute(name))
	end
	model:SetAttribute("UID", model.Name)
	model:SetAttribute("SourceEggUID", egg:GetAttribute("UID"))
	model:SetAttribute("MonsterId", monsterId)
	model:SetAttribute("MonsterName", definition.MonsterName)
	model:SetAttribute("IsMonster", true)
	model:SetAttribute("VisualScale", model:GetScale())
	model:SetAttribute("BaseIncome", definition.BaseIncome)
	model:SetAttribute("BaseRarity", definition.Rarity)
	model:SetAttribute("IndexId", definition.IndexId)
	model:SetAttribute("Icon", definition.Icon)
	model:SetAttribute("ModelName", definition.ModelName)
	model:SetAttribute("MonsterBiome", definition.Biome)
	local income = Config.CalculateIncome(monsterId, egg:GetAttribute("Rarity"), egg:GetAttribute("Size"))
	if not income then model:Destroy(); error("Invalid monster income metadata") end
	model:SetAttribute("FinalIncome", income)
	return model
end

-- Calculate from server configuration, not the displayed FinalIncome attribute.
function Service.GetIncome(player)
	local plot = PlotService.GetPlot(player)
	if not plot or not PlotService.IsOwner(player, plot) then return 0 end
	local folder = plot:FindFirstChild("PlacedEggs")
	if not folder then return 0 end
	local total = 0
	local seen = {}
	for _, model in ipairs(folder:GetChildren()) do
		local uid = model:GetAttribute("UID")
		if model:IsA("Model") and model:GetAttribute("IsMonster") == true
			and model:GetAttribute("OwnerUserId") == player.UserId
			and type(uid) == "string" and uid ~= "" and not seen[uid] then
			seen[uid] = true
			total += Config.CalculateIncome(model:GetAttribute("MonsterId"), model:GetAttribute("Rarity"), model:GetAttribute("Size")) or 0
		end
	end
	return total
end

function Service.AddLabel(monster)
	if not monster or not monster:IsA("Model") or not monster.PrimaryPart then return end
	local old = monster:FindFirstChild("MonsterLabel")
	if old then old:Destroy() end
	local frame, size = monster:GetBoundingBox()
	local gui = Instance.new("BillboardGui")
	gui.Name = "MonsterLabel"
	gui.Size = UDim2.fromOffset(230, 75)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Adornee = monster.PrimaryPart
	gui.StudsOffsetWorldSpace = frame.Position - monster.PrimaryPart.Position + Vector3.new(0, size.Y / 2 + 1.5, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.Text = string.format("%s\n%s | %s\n$%g/sec", monster:GetAttribute("MonsterName"),
		monster:GetAttribute("Rarity"), monster:GetAttribute("Size"), monster:GetAttribute("FinalIncome"))
	label.Parent = gui
	gui.Parent = monster
end

return Service
