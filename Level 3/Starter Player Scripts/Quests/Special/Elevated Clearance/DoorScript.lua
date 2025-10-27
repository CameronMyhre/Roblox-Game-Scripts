-- Services --
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")

-- Configurations
local configs = modules:WaitForChild("Configs")
local presets = require(configs:WaitForChild("HighlightPreset"))

-- Enums
local enums = modules:WaitForChild("Enums")
local highlightMode = require(enums:WaitForChild("HighlightMode"))

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")
local interactionEvents = bindableEvents:WaitForChild("Interaction")
local highlightBindableEvent = interactionEvents:WaitForChild("HighlightEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local keycardQuest1 = quests:WaitForChild("Elevated Clearance")

local door = keycardQuest1:WaitForChild("KeycardDoor")
local doorModel = door:WaitForChild("DoorModel")
local doorPrimaryPart = doorModel:WaitForChild("Hitbox")
local clickDetector = doorPrimaryPart:WaitForChild("ClickDetector")

-- Settings --
local cooldown = .2
local defaultTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Pivot stuff bc roblox sucks --
doorPrimaryPart.PivotOffset = doorPrimaryPart:GetPivot()
local pivot = doorPrimaryPart.PivotOffset
local offset = pivot:ToObjectSpace(doorPrimaryPart.CFrame)
local closedCFrame = pivot
local openCFrame =  pivot * CFrame.Angles(0, math.rad(120), 0)

-- Misc --
local tweenConnection
local isOpen = false
local cooldownActive = false
local activeTween = nil

-- Door Functions --
local function playDoorTween()
	-- stop any current tween
	if activeTween and activeTween.PlaybackState == Enum.PlaybackState.Playing then
		activeTween:Cancel()
	end

	local targetPivot = isOpen and closedCFrame or openCFrame
	local tween = tweenService:Create(doorPrimaryPart, defaultTweenInfo, { PivotOffset = targetPivot })
	activeTween = tween

	-- capture THIS tween and THIS connection in locals so we don't reference the global later
	local conn
	conn = runService.Heartbeat:Connect(function()
		-- keep the door’s CFrame in sync with the changing PivotOffset
		doorPrimaryPart.CFrame = doorPrimaryPart.PivotOffset:ToWorldSpace() * offset

		-- disconnect when THIS tween finishes or gets cancelled
		local state = tween.PlaybackState
		if state == Enum.PlaybackState.Completed or state == Enum.PlaybackState.Cancelled then
			if conn then conn:Disconnect(); conn = nil end
		end
	end)

	-- also belt-and-suspenders: disconnect on Completed (in case a frame is skipped)
	tween.Completed:Once(function()
		if conn then conn:Disconnect(); conn = nil end
	end)

	tween:Play()
	isOpen = not isOpen
end

local function openCloseDoor()

	-- Stop the rest of the code from running if the cooldown is active
	if cooldownActive then return end

	-- Enable the colldown to prevent players from spam opening/closing the door.
	cooldownActive = true

	-- Open / close the door if it is opened or closed.
	playDoorTween()

	-- Wait for the cooldown to end and then disable the debounce variable.
	task.wait(cooldown)
	cooldownActive = false
end

-- Door Events --
clickDetector.MouseClick:Connect(openCloseDoor)

-- Highlight Functions --
local function mouseEnter(plr)
	highlightBindableEvent:Fire(plr, doorModel, highlightMode.Show, presets.Default)
end

local function mouseLeaver(plr)
	highlightBindableEvent:Fire(plr, doorModel, highlightMode.Hide)
end

-- Highlight Events --
clickDetector.MouseHoverEnter:Connect(mouseEnter)
clickDetector.MouseHoverLeave:Connect(mouseLeaver)