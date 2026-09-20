local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Inventory = require(script.Parent:WaitForChild("EggInventoryService"))
local Placement = require(ReplicatedStorage.Modules:WaitForChild("EggPlacement"))
PlotService.Start()

-- Also support Studio sessions where only the script folders were synced.
local remote = ReplicatedStorage:FindFirstChild("PlaceEggEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PlaceEggEvent"
	remote.Parent = ReplicatedStorage
end
assert(remote:IsA("RemoteEvent"), "[EggPlacement] ReplicatedStorage.PlaceEggEvent must be a RemoteEvent; an object with the wrong class already has that name.")
local lastRequest = {}

remote.OnServerEvent:Connect(function(player, uid, point)
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < 0.15 then return end
	lastRequest[player] = now
	if type(uid) ~= "string" or #uid > 128 or typeof(point) ~= "Vector3" then return end
	for _, value in ipairs({point.X, point.Y, point.Z}) do
		if value ~= value or math.abs(value) == math.huge then return end
	end
	local plot = PlotService.GetPlot(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not plot or not PlotService.IsOwner(player, plot) or not root or not humanoid or humanoid.Health <= 0 then return end
	local entry = Inventory.GetEquippedEntry(player, uid)
	if not entry then return end
	local visual = entry.template:FindFirstChild("EggVisual")
	if not visual then return end
	local _, size = visual:GetBoundingBox()
	if not Placement.IsValid(plot, point, size, root.Position) then return end
	local egg = visual:Clone()
	egg.Name = uid
	for name, value in pairs(entry.record:GetAttributes()) do egg:SetAttribute(name, value) end
	egg:SetAttribute("Placed", true)
	for _, object in ipairs(egg:GetDescendants()) do
		if object:IsA("JointInstance") or object:IsA("Constraint") then object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide, object.CanTouch, object.CanQuery = false, false, true
		end
	end
	Placement.Move(egg, Placement.GetFrame(plot.Place, point, size))
	-- Validation, consumption and publication never yield; repeated clicks cannot duplicate a UID.
	if Inventory.ConsumeEquipped(player, uid) then egg.Parent = plot.PlacedEggs else egg:Destroy() end
end)

Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
remote:SetAttribute("ServerReady", true)
