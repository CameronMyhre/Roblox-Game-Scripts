-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

local tweenService = game:GetService("TweenService")
local scaleTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
local guiFadeTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local playerGui: PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local configs = modules:WaitForChild("Configs")
local clientEffectData = require(configs:WaitForChild("ClientEffectData"))

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")
local guiBindableEvents = bindableEvents:WaitForChild("GUI")
local toggleGUIBindableEvent = guiBindableEvents:WaitForChild("ToggleGUI")

-- Remote Events --
local remoteEvents = framework:WaitForChild("Remote Events")
local effectEvents = remoteEvents:WaitForChild("Effects")

local effectAddedEvent = effectEvents:WaitForChild("EffectAdded")
local effectChangedEvent = effectEvents:WaitForChild("EffectChanged")
local effectRemovedEvent = effectEvents:WaitForChild("EffectRemoved")
local effectsRemovedEvent = effectEvents:WaitForChild("EffectsRemoved") -- Exists to limit the amount of remote events fired on death.

-- Objects --
local camera = workspace.CurrentCamera

-- GUI --
local gui = script.Parent
local container = gui:WaitForChild("Container")
local template = container:WaitForChild("Template")

local effectDetails = gui:WaitForChild("Effect Details")
local effectDetailsBackground = effectDetails:WaitForChild("Background")
local detailTitle = effectDetailsBackground:WaitForChild("Effect Name")
local detailTemplate = effectDetailsBackground:WaitForChild("Template")

-- Settings --
local timeFormatString = "%02d:%02d"

local updateTimeFrequency = 0.3 -- Seconds
local defaultNullEffect = clientEffectData.Null

local clonedDetailName = "Effect-Details"
local effectDetailOffset = Vector2.new(0, -.05)

local overlappingCheckTime = 0.5

-- Flags --
local detailsVisible = false
local guiEnabled = false

-- Storage --
local displayedEffectName = ""

local accumulatedTime = 0
local accumulatedGuiOverlapCheckTime = 0

local activeEffectData = {}

local activeEffectDetails: {TextLabel} = {}

-- Functions --
-- Utility --
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = math.floor(seconds % 60)
	return string.format(timeFormatString, minutes, remainingSeconds)
end

local function getEffectData(effectName: string)
	
	-- Attempt to find data for the effect with the given name.
	local effectData = clientEffectData[effectName]
	
	return effectData or defaultNullEffect
end

local function isOverlappingDescendent(): boolean
	
	-- Reset the accumulated time.
	accumulatedGuiOverlapCheckTime = 0
	
	-- Get the mouse position.
	local mousePosition = userInputService:GetMouseLocation() - guiService:GetGuiInset()
	local overlappingGui = playerGui:GetGuiObjectsAtPosition(mousePosition.X, mousePosition.Y)
	
	-- Loop through all of the GUI objects and verify that an effect is being hovered over.
	for _, guiObject in ipairs(overlappingGui) do
		
		-- If the gui object is a descendent of the container, return true.
		if guiObject:IsDescendantOf(container) then
			return true
		end
	end
	
	-- No gui object was found that matched the criteria.
	return false
end

-- Effect Details --
local function convertToScaledPosition(screenPosition)
	
	-- viewport in pixels
	local viewport = camera.ViewportSize
	local vw, vh = viewport.X, viewport.Y

	-- mouse → scale (0..1) + your offset (offset is in scale units)
	local targetX = (screenPosition.X / vw) + effectDetailOffset.X
	local targetY = (screenPosition.Y / vh) + effectDetailOffset.Y

	-- card size in scale (uses actual on-screen size)
	local wScale = effectDetails.AbsoluteSize.X / vw
	local hScale = effectDetails.AbsoluteSize.Y / vh

	-- with AnchorPoint = 0.5,0.5 the center may move from half-size .. 1 - half-size
	local minX, maxX = 0.5 * wScale, 1 - 0.5 * wScale
	local minY, maxY = 0.5 * hScale, 1 - 0.5 * hScale

	return Vector2.new(
		math.clamp(targetX, minX, maxX),
		math.clamp(targetY, minY, maxY)
	)
end

local function moveDetailDisplay()

	-- Get the player's mouse position
	local mouseScreenPosition = userInputService:GetMouseLocation()

	-- Convert the position to scale (% of the screen)
	local scaledMousePosition = convertToScaledPosition(mouseScreenPosition)

	-- Move the GUI to the position.
	effectDetails.Position = UDim2.new(scaledMousePosition.X, 0, scaledMousePosition.Y, -effectDetailsBackground.AbsoluteSize.Y / 2)
end

local function clearOldDetails()
	
	-- Loop through all the old detail elements and destroy them.
	for _, detailText in ipairs(activeEffectDetails) do
		detailText:Destroy()
	end
end

local function loadEffectDetailGUI(effectName: string)
	
	-- Get the effect details.
	local effectData = getEffectData(effectName)
	
	-- Update the title text with the effect name.
	detailTitle.Text = effectData.name
	
	-- Split the string at every line break. This needs to be done to work with the GUI.
	local detailStrings = string.split(effectData.description, "\n")
	
	-- For each line break, clone a new text label with the respective text.
	for _, detailString in ipairs(detailStrings) do
		
		-- Clone the GUI.
		local detailClone = detailTemplate:Clone()
		detailClone.Text = detailString
		detailClone.Visible = true
		detailClone.Parent = effectDetailsBackground
		
		-- Store the GUI so that it can be removed later.
		table.insert(activeEffectDetails, detailClone)
	end
end

local function showDetails(effectName: string)

	-- Make the GUI Visible
	effectDetails.GroupTransparency = 0
	
	-- Return if we are trying to display the same effect.
	if effectName == displayedEffectName then
		return
	end
	
	-- If there is a currently shown effect. clear its info.
	if #activeEffectDetails > 0 then
		clearOldDetails()
	end
	
	-- Update the displayed effect name and show the new effect's info.
	displayedEffectName = effectName
	loadEffectDetailGUI(effectName)
	
	-- Toggle the flag to show the GUI is now visible.
	detailsVisible = true
end

local function hideDetails()

	-- Make the GUI invisible --
	effectDetails.GroupTransparency = 1
	
	-- Clear the effect name.
	displayedEffectName = ""
	
	-- Toggle the flag to show the GUI is now invisible.
	detailsVisible = false
end

-- GUI Update Events --
local function updateGui(guiObject: GuiObject, remainingTime: number)
	
	-- Find the GUI's duration text.
	local durationText = guiObject:FindFirstChild("Time")
	if not durationText then
		return
	end
	
	-- Update the GUI's time.
	local formattedTimeText = formatTime(remainingTime)
	durationText.Text = formattedTimeText
end

-- GUI Interaction Events --
local function mouseEnter(effectName: string, effectObject: GuiObject)
	
	-- Show the details for the displayed effect.
	showDetails(effectName)
	
	-- Increase the size of the GUI element.
	local uiScale = effectObject:FindFirstChild("UIScale")
	if not uiScale then
		return
	end
	
	-- Tween the size of the GUI element back to the large state.
	tweenService:Create(uiScale, scaleTween, {
		Scale = 1.1
	}):Play()
end

local function mouseLeave(effectName: string, effectObject: GuiObject)

	-- If the details are currently being shown for this effect, hide the effect details.
	if displayedEffectName == effectName then
		hideDetails()
	end
	
	-- Decrease the size of the GUI element (if possible)
	local uiScale = effectObject:FindFirstChild("UIScale")
	if not uiScale then
		return
	end

	-- Tween the size of the GUI element back to normal.
	tweenService:Create(uiScale, scaleTween, {
		Scale = 1
	}):Play()
end

-- GUI Setup --
local function createGuiElement(effectData: clientEffectData.effectData, effectName: string, effectDuration: number)
	
	-- Clone the effect template GUI.
	local guiClone = template:Clone()
	
	-- Configure the overarching GUI element.
	guiClone.Name = effectName
	guiClone.LayoutOrder = effectData.layoutOrder
	guiClone.Visible = true
	guiClone.Interactable = true
	
	if effectData.specialBackgroundColor then
		guiClone.ImageColor3 = effectData.specialBackgroundColor -- Image is used for the background, so we update the image color.
	end
	
	-- Update the remaining GUI elements.
	guiClone.EffectImage.Image = effectData.imageId
	
	local durationText = formatTime(effectDuration)
	guiClone.Time.Text = durationText
	
	-- Setup Events --
	guiClone.MouseEnter:Connect(function ()
		mouseEnter(effectName, guiClone)
	end)
	
	guiClone.MouseLeave:Connect(function ()
		mouseLeave(effectName, guiClone)
	end)
	
	-- Parent the GUI element and return it.
	guiClone.Parent = container
	return guiClone
end

local function effectAdded(effectName: string, duration: number)
	
	-- Attempt to get the effect data.
	local effectData = getEffectData(effectName)
	
	-- Create a GUI element for the effect.
	local guiButton = createGuiElement(effectData, effectName, duration)
	
	-- Format and store all of the GUI information in an array.
	local formattedData = {
		button = guiButton,
		remainingTime = duration
	}
	
	activeEffectData[effectName] = formattedData
end

local function effectChanged(effectName: string, newDuration: number)
	
	-- Verify a GUI element exists. If it doesn't (e.g. a element got deleted prematurely, create a new one)
	local effectData = activeEffectData[effectName]
	if not effectData then
		effectAdded(effectName, newDuration)
		return
	end
	
	-- Update the remaining time for the effect.
	effectData.remainingTime = newDuration
	
	-- Force update the GUI element.
	updateGui(effectData.button, newDuration)
end

local function removeEffect(effectName: string)
	
	-- Verify the GUI element exists.
	local effectData = activeEffectData[effectName]
	if not effectData or effectData == nil	then
		return
	end
	
	-- Delete the GUI element.
	if effectData.button then
		effectData.button:Destroy()
	end
	
	-- Hide the display GUI if it is currently visible for the removed effect.
	if displayedEffectName == effectName then
		hideDetails()
	end
	
	-- Clear out the stored data.
	activeEffectData[effectName] = nil
end

local function removeEffects(effectNames: {string})
	
	-- Attempt to clear out all effects.
	for _, effectName in ipairs(effectNames) do
		removeEffect(effectName)
	end
end

-- Event Functions --
local function periodic(deltaTime: number)
	
	-- If the detail preview is open, then update its position.
	if detailsVisible then
		moveDetailDisplay()
		
		-- Increment the accumulated gui overlap check time.
		accumulatedGuiOverlapCheckTime += deltaTime
		if accumulatedGuiOverlapCheckTime >= overlappingCheckTime then
			
			-- Reset the accumulated time.
			accumulatedGuiOverlapCheckTime = 0
			
			-- Hide the details if the player is not overlapping an effect.
			if not isOverlappingDescendent() then
				hideDetails()
			end
		end
	end
	
	-- Increment accumulated time.
	accumulatedTime += deltaTime
	
	-- If the accumulated time is not enough to update the GUI, return.
	if accumulatedTime < updateTimeFrequency then
		return
	end
	
	-- Update all the effect GUI.
	for effectName, data in pairs(activeEffectData) do
		
		-- Update the remaining time.
		data.remainingTime -= accumulatedTime
		
		-- If the effect is over, remove it. Otherwise, update the remaining time.
		if data.remainingTime <= 0 then
			removeEffect(effectName)
		else
			updateGui(data.button, data.remainingTime)
		end
	end
	
	-- Reset the accumulated time.
	accumulatedTime = 0
end

local function toggleGUI(toActive: boolean)

	local targetTransparency
	if toActive then
		targetTransparency = 0 -- Visible GUI.
	else
		targetTransparency = 1 -- Invisible GUI.

		-- Hide the details of the GUI.
		hideDetails()
	end
	
	-- Toggle the intractability of the GUI
	container.Interactable = toActive
	
	-- Fade the GUI in/out.
	tweenService:Create(container, guiFadeTween, {
		GroupTransparency = targetTransparency
	}):Play()
end

-- Events --
effectAddedEvent.OnClientEvent:Connect(effectAdded)
effectChangedEvent.OnClientEvent:Connect(effectChanged)
effectRemovedEvent.OnClientEvent:Connect(removeEffect)
effectsRemovedEvent.OnClientEvent:Connect(removeEffects)

toggleGUIBindableEvent.Event:Connect(toggleGUI)

runService.Heartbeat:Connect(periodic)