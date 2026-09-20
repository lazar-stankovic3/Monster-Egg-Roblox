local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Placement = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EggPlacement"))
local remote = ReplicatedStorage:WaitForChild("PlaceEggEvent", 10)
if not remote or not remote:IsA("RemoteEvent") then
	warn("[EggPlacement] PlaceEggEvent missing. Stop Play, sync Rojo including default.project.json, then start a new session.")
	return
end
task.delay(10, function()
	if not remote:GetAttribute("ServerReady") then
		warn("[EggPlacement] Server is not ready. Check ServerScriptService.Server.EggPlacementSystem and earlier server Output errors.")
	end
end)
local ghost, equipped, size, point
local valid = false
local lastColor
local gray = Color3.fromRGB(175, 175, 175)
local red = Color3.fromRGB(235, 65, 65)

local function clear()
	if ghost then ghost:Destroy() end
	ghost, equipped, size, point, lastColor = nil, nil, nil, nil, nil
	valid = false
end

local function makePreview(tool)
	clear()
	local visual = tool:FindFirstChild("EggVisual")
	if not visual then return end
	ghost = visual:Clone()
	ghost.Name = "LocalEggPlacementPreview"
	for _, object in ipairs(ghost:GetDescendants()) do
		if object:IsA("JointInstance") or object:IsA("Constraint") or object:IsA("LuaSourceContainer")
			or object:IsA("SurfaceAppearance") or object:IsA("Decal") or object:IsA("Texture")
			or object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
			or object:IsA("Light") or object:IsA("BillboardGui") or object:IsA("SurfaceGui")
			or object:IsA("Highlight") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide, object.CanTouch, object.CanQuery = false, false, false
			object.Transparency = if object.Transparency >= 1 then 1 else 0.6
			object.Material = Enum.Material.SmoothPlastic
			object.Reflectance = 0
			object.CastShadow = false
			if object:IsA("UnionOperation") then object.UsePartColor = true end
			if object:IsA("MeshPart") then object.TextureID = "" end
		elseif object:IsA("SpecialMesh") then
			object.TextureId = ""
			object.VertexColor = Vector3.new(1, 1, 1)
		end
	end
	ghost:PivotTo(CFrame.new())
	local _, bounds = ghost:GetBoundingBox()
	size = bounds
	equipped = tool
	ghost.Parent = workspace
end

local function updatePreview()
	valid = false
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not tool or not tool:GetAttribute("IsEggTool") or not root or not humanoid or humanoid.Health <= 0 then
		if ghost then clear() end
		return
	end
	if equipped ~= tool then makePreview(tool) end
	if not ghost then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	-- Roblox supplies the cursor ray in the correct screen coordinate space.
	-- Do not subtract GUI inset from viewport coordinates manually.
	local ray = mouse.UnitRay
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character, ghost}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	point = if hit then hit.Position else ray.Origin + ray.Direction * 30
	local plots = workspace:FindFirstChild("Plots")
	local name = player:GetAttribute("PlotName")
	local plot = plots and type(name) == "string" and plots:FindFirstChild(name)
	local place = plot and plot:FindFirstChild("Place")
	valid = remote:GetAttribute("ServerReady") == true and hit ~= nil and place ~= nil and hit.Instance == place
		and plot:GetAttribute("OwnerUserId") == player.UserId
		and Placement.IsValid(plot, point, size, root.Position)
	local frame = if place and hit and hit.Instance == place
		then Placement.GetFrame(place, point, size)
		else CFrame.new(point + Vector3.new(0, size.Y / 2, 0))
	Placement.Move(ghost, frame)
	local color = if valid then gray else red
	if color ~= lastColor then
		for _, object in ipairs(ghost:GetDescendants()) do
			if object:IsA("BasePart") then object.Color = color end
		end
		lastColor = color
	end
end

RunService:BindToRenderStep("EggPlacementPreview", Enum.RenderPriority.Camera.Value + 1, updatePreview)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	-- Recompute at click time rather than sending the previous rendered frame's point.
	updatePreview()
	if valid and equipped and equipped.Parent == player.Character and point then
		remote:FireServer(equipped:GetAttribute("UID"), point)
	end
end)

player.CharacterRemoving:Connect(clear)
