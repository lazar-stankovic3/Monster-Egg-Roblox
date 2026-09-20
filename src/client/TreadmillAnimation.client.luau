local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character, humanoid, animator, track, animation, diedConnection
local generation = 0

local function stop()
	if track then
		track:Stop(0.15)
		track:Destroy()
		track = nil
	end
	if animation then animation:Destroy(); animation = nil end
end

local function update()
	if not player:GetAttribute("TreadmillLocked") or not humanoid or humanoid.Health <= 0
		or character ~= player.Character or not animator then
		stop()
		return
	end
	if track then return end
	-- Match the existing movement animation instead of relying on Running speed:
	-- the treadmill holds the root still, so the normal Animate script sees zero speed.
	local animate = character:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local source = run and run:FindFirstChildWhichIsA("Animation", true)
	local id = source and source.AnimationId
	if not id or id == "" then
		id = if humanoid.RigType == Enum.HumanoidRigType.R6
			then "rbxassetid://180426354" else "rbxassetid://110696808533851"
	end
	animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, result = pcall(function() return animator:LoadAnimation(animation) end)
	if not ok then
		warn("[TreadmillAnimation] " .. tostring(result))
		stop()
		return
	end
	track = result
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.15, 1, 1)
end

local function setup(nextCharacter)
	generation += 1
	local current = generation
	stop()
	if diedConnection then diedConnection:Disconnect(); diedConnection = nil end
	character, humanoid, animator = nextCharacter, nil, nil
	local nextHumanoid = nextCharacter:WaitForChild("Humanoid", 10)
	local nextAnimator = nextHumanoid and nextHumanoid:WaitForChild("Animator", 10)
	if current ~= generation or player.Character ~= nextCharacter then return end
	if not nextHumanoid or not nextAnimator then return end
	humanoid, animator = nextHumanoid, nextAnimator
	diedConnection = humanoid.Died:Connect(stop)
	update()
end

player:GetAttributeChangedSignal("TreadmillLocked"):Connect(update)
player.CharacterAdded:Connect(setup)
player.CharacterRemoving:Connect(function()
	generation += 1
	stop()
	if diedConnection then diedConnection:Disconnect(); diedConnection = nil end
	character, humanoid, animator = nil, nil, nil
end)
if player.Character then task.spawn(setup, player.Character) end
