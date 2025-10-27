-- Services --
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local contextActionService = game:GetService("ContextActionService")
local runService = game:GetService("RunService")

local tweenService = game:GetService("TweenService")
local guiFadeTween = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local clickTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad)

-- Bindable Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local bindableEvent = remoteFramework:WaitForChild("Bindable Events")
local guiBindableEvents = bindableEvent:WaitForChild("GUI")
local toggleGuiBindableEvent = guiBindableEvents:WaitForChild("ToggleGUI")

-- Remote Events --
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local remoteFlashlightEvents = remoteEvents:WaitForChild("Flashlight")
local equipFlashlightEvent = remoteFlashlightEvents:WaitForChild("EquipFlashlight")
local flashlightDataUpdatedEvent = remoteFlashlightEvents:WaitForChild("FlashlightDataUpdated")

local guiEvents = remoteEvents:WaitForChild("GUI")
local toggleGuiEvent = guiEvents:WaitForChild("ToggleGUI")

-- Remote Functions --
local remoteFunctions = remoteFramework:WaitForChild("Remote Functions")
local getFlashlightDataFunction = remoteFunctions:WaitForChild("GetFlashlightData")

-- GUI --
local gui = script.Parent

local container = gui:WaitForChild("Container")
local closeButton = container:WaitForChild("CloseButton")
local background = container:WaitForChild("Background")
local scrollingContainer = background:WaitForChild("ScrollingFrame")
local template = scrollingContainer:WaitForChild("Template")

-- SFX --
local clickSFX = gui:WaitForChild("Click")

-- Settings --
local openGUIActionName = "openGUI"
local actionKeybind = Enum.KeyCode.F

local missingDataName = "???"
local statsFormat = "Brightness: %s   Range: %s  "
local unownedText = "(Unowned)"

local clickBackgroundColor = Color3.fromRGB(255, 255, 255)
local hoverBackgroundColor = Color3.fromRGB(89, 89, 89)
local regularBackgroundColor = Color3.fromRGB(0, 0, 0)

local equipTransparency = 0.6
local regularTransparency = 0.8

local unownedColorMultiplier = 0.8
local hoverColorMultiplier = 1.4

local updateTime = 0.4

local debounceTime = 0.2

-- Flags --
local isActive = false
local setupData = false
local debounce = false
local locked = false

-- Storage --
local equippedButton
local accumulatedTime = 0

-- Functions --
-- Utility --
local function multiplyColor3ByScalar(color3: Color3, scalar: number)
	
	-- Multiply each value of the color3 by the scalar.
	local r = color3.R * scalar
	local g = color3.G * scalar
	local b = color3.B * scalar
	
	-- Return a new color3 with the calculated values.
	return Color3.fromRGB(r * 255, g * 255, b * 255)
end

-- GUI Effects --
local function toggleEquippedEffects(button, shouldBeEnabled: boolean)
	
	-- Reset the background transparency of the equipped button.
	if shouldBeEnabled then
		button.BackgroundTransparency = equipTransparency
	else
		button.BackgroundTransparency = regularTransparency
	end

	-- Update the equipped text.
	local info = button:FindFirstChild("Info")
	if not info then
		return
	end
	
	local title = info:FindFirstChild("Title")
	if not title then
		return
	end
	
	local equippedText = title:FindFirstChild("EquippedStatus")
	if not equippedText then
		return
	end
	
	equippedText.Visible = shouldBeEnabled
end

local function updateEquipEffects(newEquippedButton: GuiButton)
	
	-- If there is a button that is currently equipped, then reset its transparency and other relevant effects.
	if equippedButton then
		toggleEquippedEffects(equippedButton, false)
	end
	
	-- Update the equipped button.
	toggleEquippedEffects(newEquippedButton, true)
	equippedButton = newEquippedButton
end

local function applyClickEffects(button: TextButton, regularBackgroundColor: Color3)
	
	-- Apply a click effect to the button.
	button.BackgroundColor3 = clickBackgroundColor
	
	return tweenService:Create(button, clickTween, {
		BackgroundColor3 = regularBackgroundColor
	})
end

-- GUI Setup Functions --
local function deleteExistingDataEntry(entryName: string)
	
	local existingClone = scrollingContainer:FindFirstChild(entryName)
	if existingClone then
		existingClone:Destroy()
	end
end

local function cloneGUIButton(dataEntry): TextButton
	
	-- Delete any existing data entry.
	deleteExistingDataEntry(dataEntry.dataName or missingDataName) -- Prevents duplicate entries.
	
	-- Clone the overarching template button.
	local templateClone = template:Clone()
	templateClone.Name = dataEntry.dataName or missingDataName
	templateClone.Visible = true
	templateClone.Interactable = true
	templateClone.LayoutOrder = dataEntry.layoutOrder
	
	-- Update the image.
	templateClone.ToolImage.Image = dataEntry.imageId
	
	-- Configure all of the flashlight information.
	local info = templateClone.Info
	info.Title.Text = dataEntry.guiName
	info.Description.Text = dataEntry.description
	info.RequirementDescription.Text = dataEntry.requirementsDescription
	
	-- Update the statistics text.
	local stats = info.Stats
	stats.StatsText.Text = string.format(statsFormat, dataEntry.brightness, dataEntry.range)
	
	-- If the GUI has a special background color, then set it.
	local hoverColor = hoverBackgroundColor
	if dataEntry.specialBackgroundColor then
		templateClone.BackgroundColor3 = dataEntry.specialBackgroundColor
		hoverColor = multiplyColor3ByScalar(dataEntry.specialBackgroundColor, hoverColorMultiplier)
	end
	
	-- Store any active tweens to help with hover effects.
	local activeTween
	
	-- Configure the GUI differently based on the requirement type.
	if dataEntry.isOwned then
		stats.Visible = true
		info.RequirementDescription.Visible = false
		
		-- Set the button to equip the flashlight.
		templateClone.Activated:Connect(function()
			
			-- If debounce is active, return.
			if debounce then
				return
			end
			
			-- Toggle debounce.
			debounce = true
			
			-- Update the equip effects if the button is not already equipped.
			if equippedButton ~= templateClone then
				updateEquipEffects(templateClone)
				equipFlashlightEvent:FireServer(dataEntry.dataName)
			end
			
			-- Apply a color change to indicate a click.
			activeTween = applyClickEffects(templateClone, hoverColor)
			activeTween:Play()
			
			-- Play a click sound effect.
			clickSFX.TimePosition = 0.2
			clickSFX:Play()
			
			-- Toggle debounce after the cooldown.
			task.wait(debounceTime)
			debounce = false
		end)
		
		-- Setup mouse hover events.
		templateClone.MouseEnter:Connect(function()

			-- Stop any playing tweens.
			if activeTween and activeTween:IsA("Tween") and activeTween.PlaybackState == Enum.PlaybackState.Playing then
				activeTween:Cancel()
			end

			-- Update the background color.
			templateClone.BackgroundColor3 = hoverColor
		end)

		templateClone.MouseLeave:Connect(function ()

			-- Stop any playing tweens.
			if activeTween and activeTween:IsA("Tween") and activeTween.PlaybackState == Enum.PlaybackState.Playing then
				activeTween:Cancel()
			end

			-- Update the background color.
			templateClone.BackgroundColor3 = dataEntry.specialBackgroundColor or regularBackgroundColor
		end)
	else
		stats.Visible = false
		info.RequirementDescription.Visible = true
		
		info.Title.TextColor3 = multiplyColor3ByScalar(info.Title.TextColor3, unownedColorMultiplier)
		info.Description.TextColor3 = multiplyColor3ByScalar(info.Description.TextColor3, unownedColorMultiplier)
		info.RequirementDescription.TextColor3 = multiplyColor3ByScalar(info.RequirementDescription.TextColor3, unownedColorMultiplier)
		
		-- Use the equipped text to show that the player does not own the flashlight.
		info.Title.EquippedStatus.Visible = true
		info.Title.EquippedStatus.Text = unownedText
		info.Title.EquippedStatus.TextColor3 = multiplyColor3ByScalar(info.Title.EquippedStatus.TextColor3, unownedColorMultiplier)
	end

	-- Parent the template clone to the scrolling container, since setup is complete.
	templateClone.Parent = scrollingContainer
	
	-- Return the created instance for storage sake.
	return templateClone
end

local function setupGUIData()
	
	-- Get the flashlight data from the server.
	local flashlightData = getFlashlightDataFunction:InvokeServer()
	
	-- Setup all the GUI elements for 
	for _, dataEntry in ipairs(flashlightData) do
		
		-- Create a GUI button for the entry.
		local guiButton = cloneGUIButton(dataEntry)
		
		-- If this flashlight is equipped, then store it's relevant information and toggle the equipped effects.
		if dataEntry.isCurrentlyEquipped then
			equippedButton = guiButton
			updateEquipEffects(equippedButton)
		end
	end
	
	-- The gui is now setup.
	setupData = true
end

-- GUI Visibility Functions --
local function toggleGUI()
	
	-- Grab the flashlight data if it has not been grabbed yet.
	if not setupData then
		setupGUIData()
	end
	
	-- Toggle isActive.
	isActive = not isActive
	container.Interactable = isActive
	
	-- Tween the GUI based on the current state.
	local targetTransparency = 1
	if isActive then
		targetTransparency = 0
		container.Visible = true
	end
	
	tweenService:Create(container, guiFadeTween, {
		GroupTransparency = targetTransparency
	}):Play()
	
	if not isActive then
		task.delay(guiFadeTween.Time, function ()
			
			-- Only hide the GUI if the GUI is inactive.
			if not isActive then
				container.Visible = false
			end
		end)
	end
end

local function actionButtonPressed(actionName, inputState, _inputObject)
	
	-- If the gui is locked, then do nothing.
	if locked then
		return
	end
	
	-- Only allow the action to be preformed if the input state is "Begin".
	if inputState ~= Enum.UserInputState.Begin then
		return
	end
	
	-- Toggle the GUI.
	if actionName == openGUIActionName then
		toggleGUI()
	end
end

local function toggleLockedGUI(toActive: boolean)
	
	-- Lock the GUI if the gui should not be active.
	locked = not toActive
	
	-- Hide the GUI if it shouldn't be active.
	if not toActive and isActive then
		toggleGUI()
	end
end

-- Debug --
local function periodic(deltaTime)
	accumulatedTime += deltaTime
	
	if accumulatedTime > updateTime then
		
		accumulatedTime = 0
		
		container.Parent = players
		container.Parent = gui
	end
end
-- Events --
contextActionService:BindAction(openGUIActionName, actionButtonPressed, true, actionKeybind)
contextActionService:SetPosition(openGUIActionName, UDim2.new(0.919, 0,0.476, 0))

closeButton.Activated:Connect(toggleGUI)
toggleGuiBindableEvent.Event:Connect(toggleLockedGUI)
toggleGuiEvent.OnClientEvent:Connect(toggleLockedGUI)

runService.Heartbeat:Connect(periodic)

-- Mobile Setup --
contextActionService:SetTitle(openGUIActionName, "Flashlights")
contextActionService:SetPosition(openGUIActionName, UDim2.new(.8, 0, -.5, 0))
