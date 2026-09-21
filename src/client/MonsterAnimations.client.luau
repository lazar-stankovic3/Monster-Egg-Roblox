local ContentProvider = game:GetService("ContentProvider")

local tracked = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })

local function animationFor(monster)
	local embedded = monster:FindFirstChild("WalkAnimation", true)
	if embedded and embedded:IsA("Animation") and embedded.AnimationId ~= "" then
		return embedded
	end

	local animationId = monster:GetAttribute("WalkAnimationId")
	if type(animationId) == "number" then animationId = tostring(animationId) end
	if type(animationId) ~= "string" or animationId == "" then return nil end
	if not string.find(animationId, "^rbxassetid://") then animationId = "rbxassetid://" .. animationId end

	local animation = Instance.new("Animation")
	animation.Name = "RuntimeWalkAnimation"
	animation.AnimationId = animationId
	animation.Parent = monster
	return animation
end

local function animatorFor(monster)
	local humanoid = monster:FindFirstChildWhichIsA("Humanoid", true)
	local controller = humanoid or monster:FindFirstChildWhichIsA("AnimationController", true)
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Name = "MonsterAnimationController"
		controller.Parent = monster
	end
	local animator = controller:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	return animator
end

local function register(monster)
	if tracked[monster] or not monster:IsA("Model") or monster:GetAttribute("IsMonster") ~= true then return end
	local animation = animationFor(monster)
	if not animation then
		-- Replication can deliver the Model before its Animation child. Retry briefly
		-- so the animation is not missed just because of that ordering.
		if pending[monster] then return end
		pending[monster] = true
		task.spawn(function()
			for _, delaySeconds in ipairs({ 0.1, 0.4, 1, 2, 4 }) do
				task.wait(delaySeconds)
				if not monster.Parent or tracked[monster] then break end
				if animationFor(monster) then
					pending[monster] = nil
					register(monster)
					return
				end
			end
			pending[monster] = nil
		end)
		return
	end

	local animator = animatorFor(monster)
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, { animation })
	end)
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if not ok then
		warn("[MonsterAnimations] Walk animation could not load for " .. monster.Name .. ": " .. tostring(track))
		return
	end
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement
	track:AdjustSpeed(1)

	local function refresh()
		if monster:GetAttribute("WanderState") == "Walking" then
			if not track.IsPlaying then track:Play(0.15) end
		elseif track.IsPlaying then
			track:Stop(0.15)
		end
	end

	local stateConnection = monster:GetAttributeChangedSignal("WanderState"):Connect(refresh)
	local ancestryConnection
	ancestryConnection = monster.AncestryChanged:Connect(function(_, parent)
		if parent then return end
		stateConnection:Disconnect()
		ancestryConnection:Disconnect()
		track:Stop(0)
		tracked[monster] = nil
	end)
	tracked[monster] = true
	refresh()
end

for _, descendant in ipairs(workspace:GetDescendants()) do register(descendant) end
workspace.DescendantAdded:Connect(function(descendant)
	register(descendant)
	local model = descendant:FindFirstAncestorOfClass("Model")
	if model then register(model) end
end)
