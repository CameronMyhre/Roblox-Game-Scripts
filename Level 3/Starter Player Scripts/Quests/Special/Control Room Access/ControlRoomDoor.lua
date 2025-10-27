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
local bindableEvents = replicatedStorage:WaitForChild("Bindable Events")
local questBindableEvents = bindableEvents:WaitForChild("Quest")
local toggleControlRoomDoorEvent = questBindableEvents:WaitForChild("ToggleControlRoomDoor")

local framework = replicatedStorage:WaitForChild("Framework")
local frameworkBindableEvents = framework:WaitForChild("Bindable Events")
local dialogEvents = frameworkBindableEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

local interactionEvents = frameworkBindableEvents:WaitForChild("Interaction")
local highlightEvent = interactionEvents:WaitForChild("HighlightEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local adminQuest = quests:WaitForChild("Administration Quest")

local door = adminQuest:WaitForChild("ControlDoor")
local frame = door:WaitForChild("Frame")
local doorModel = door:WaitForChild("DoorModel")
local doorPrimaryPart = doorModel:WaitForChild("Hitbox")
local clickDetector = doorPrimaryPart:WaitForChild("ClickDetector")

-- SFX --
local unlockSFX = frame:WaitForChild("UnlockSFX")

-- Dialog Settings --
local lockedDialog = "~!~BigWave,Fade~It's locked. ~"

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

local doorActive = false
local dialogCooldownActive = false

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

local function playLockedDialog()
	
	-- Toggle debounce.
	dialogCooldownActive = true
	
	-- Play relevent dialog.
	dialogEvent:Fire(lockedDialog, Enum.Font.Gotham, 2, 1, true)
	
	-- Toggle debounce.
	task.wait(5)
	dialogCooldownActive = false
end

local function openCloseDoor()

	-- Return if the door is locked.
	if not doorActive then
		
		-- Play dialog if possible.
		if not dialogCooldownActive then
			playLockedDialog()
		end

		return
	end
	
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

local function toggleIsActive(shouldBeActive: boolean)
	
	-- Toggle the state of the door depending on what is requested.
	if shouldBeActive then
		
		if doorActive then
			return
		end
			
		-- The door is now active.
		doorActive = true
		
		task.wait(3) -- Delay to prevent switch SFX from overlapping.
		
		-- Play unlock SFX.
		unlockSFX:Play()
	else
		
		-- Close the door if it is open.
		if isOpen then
			playDoorTween()
		end
		
		-- Prevent the door from being opened.
		doorActive = false
	end
end

-- Events --
clickDetector.MouseClick:Connect(openCloseDoor)
toggleControlRoomDoorEvent.Event:Connect(toggleIsActive)

-- Highlight Functions --
local function mouseEnter(plr)
	highlightEvent:Fire(doorModel, highlightMode.Show, presets.Default)
end

local function mouseLeaver(plr)
	highlightEvent:Fire(doorModel, highlightMode.Hide)
end

-- Highlight Events --
clickDetector.MouseHoverEnter:Connect(mouseEnter)
clickDetector.MouseHoverLeave:Connect(mouseLeaver)

for _,v in ipairs(game.Workspace["Floor 2"].Shelves:GetChildren()) do
	
	local children = v:GetChildren()
	local part = children[1]
	if part and part:IsA("Part") then
		
		table.remove(children, 1)
		
		local union: UnionOperation = part:UnionAsync(children)
		v:ClearAllChildren()
		union.Parent = v
		union.CollisionFidelity = Enum.CollisionFidelity.Box
	end
end