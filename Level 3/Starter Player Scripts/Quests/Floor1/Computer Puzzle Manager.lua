-- Services --
local players = game:GetService("Players")
local localPlr = players.LocalPlayer
local mouse = localPlr:GetMouse()

local runsService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local soundService = game:GetService("SoundService")

local tweenService = game:GetService("TweenService")
local fadeTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local quickFade = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local slowFade = TweenInfo.new(.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local superSlowFade = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local guiEvents = bindableEvents:WaitForChild("GUI")
local toggleGUIBindableEvent = guiEvents:WaitForChild("ToggleGUI")

local vfxBindableEvents = bindableEvents:WaitForChild("VFX")
local toggleVFXBindableEvent = vfxBindableEvents:WaitForChild("ToggleVFX")

local movementBindableEvents = bindableEvents:WaitForChild("Movement")
local forceStateBindableEvent = movementBindableEvents:WaitForChild("ForceMovementStateEvent")

local dialogEvents = bindableEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

-- Modules
local modules = framework:WaitForChild("Modules")

local enums = modules:WaitForChild("Enums")
local movementStateEnum = require(enums:WaitForChild("MovementState"))

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local questEvents = remoteEvents:WaitForChild("Quest")
local elevateEvent = questEvents:WaitForChild("ElevateEvent")

local frameworkRemoteEvents = framework:WaitForChild("Remote Events")
local playerEvents = frameworkRemoteEvents:WaitForChild("Player")
local deathEvent = playerEvents:WaitForChild("DeathEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local computerQuest = quests:WaitForChild("Computer Quest")

local computerScreen = computerQuest:WaitForChild("Computer Screen")
local terminalScreen = computerScreen:WaitForChild("Screen")
local sliderPoint = terminalScreen:WaitForChild("SliderPoint")
local sliderPoint2 = terminalScreen:WaitForChild("SliderPoint2")

local digitLocationsFolder = computerQuest:WaitForChild("Digit Locations")

local elevatorQuest = quests:WaitForChild("Elevator")
local elevatorComputer = elevatorQuest:WaitForChild("Computer")
local screen = elevatorComputer:WaitForChild("Screen")
local elevatorProgressGUI = screen:WaitForChild("StatusGUI")
local elevatorProgressContainer = elevatorProgressGUI:WaitForChild("Frame")
local progressContainer = elevatorProgressContainer:WaitForChild("Lock")
local progressStatusText = progressContainer:WaitForChild("Status")
local progressLabelText = progressContainer:WaitForChild("Label")

local elevatorProgress = elevatorQuest:WaitForChild("Progress")

-- GUI --
local gui = terminalScreen:WaitForChild("Terminal Screen")

local closeButtonContainer = gui:WaitForChild("CloseButton")
local closeButton = closeButtonContainer:WaitForChild("Button")

local login = gui:WaitForChild("Login")
local visualText = login:WaitForChild("Visual Text")

local terminalTemplate = visualText:WaitForChild("Template")

local passwordEnter = visualText:WaitForChild("Password Enter")
local passwordHeader = passwordEnter:WaitForChild("Label")
local passwordInput = passwordEnter:WaitForChild("Input")

local inputLine = visualText:WaitForChild("Input")
local commandInput = inputLine:WaitForChild("Input")

local decrypt = gui:WaitForChild("Decrypt")
local decryptInput = decrypt:WaitForChild("Input Field")
local garble = decryptInput:WaitForChild("Garble")

local roundText = decrypt:WaitForChild("Rounds")
local timeText = decrypt:WaitForChild("Timer")

local slider = decrypt:WaitForChild("Slider")
local sliderBody = slider:WaitForChild("Body")
local sliderOverlay = sliderBody:WaitForChild("Overlay")
local sliderKnob = sliderBody:WaitForChild("Slider")

local accessDenied = gui:WaitForChild("Denied")

local digitUI = script:WaitForChild("Digit")

-- Overarching Settings --
local wrongColor = Color3.fromRGB(255, 79, 66)
local wrongSelectedColor = Color3.fromRGB(255, 23, 23)
local correctTextColor = Color3.fromRGB(86, 255, 56)
local correctSelectedColor = Color3.fromRGB(4, 255, 0)

-- Flags --
local sliderDown = false
local minigameActive = false
local mouseTouchingOverlay = false
local mouseTouchingSlider = false
local mouseDown = false

local decryptActive = true
local terminalActive = false




--[[---------------------------------------------------------------------
TERMINAL
--]]---------------------------------------------------------------------
-- Objects --
local administrationQuest = quests:WaitForChild("Administration Quest")
local adminProgress = administrationQuest:WaitForChild("Progress")

-- Settings --
local adminLockDisabledDialog = "~!~Shatter,Delay~A hidden lock clicks open.~ "
local commands = {
	["help"] = {
		accessLevel = 1,
		name = "Help",
		helpText = "Lists the functions of all commands"
	},
	["accesslevel"] = {
		accessLevel = 1,
		name = "AccessLevel",
		helpText = "Displays this terminals access level."
	},
	["disableelevatorsecurity"] = {
		accessLevel = 1,
		name = "DisableElevatorSecurity",
		helpText = "Turns off the security protecting the elevator"
	},
	["elevate"] = {
		accessLevel = 2,
		name = "Elevate",
		helpText = "Elevates the terminal to administrator privileges"
	},
	["unlockadministration"] = {
		accessLevel = 5,
		name = "UnlockAdministration",
		helpText = "Removes the remote lock on the administration section door."
	},
}

-- Flags --
local canUseElevatedCommands = false
local adminUnlocked = false

-- Storage --
local accessLevel = 1

-- Utility Functions --
local function createTerminalItem(text: string)

	-- Create the new terminal item.
	local templateClone = terminalTemplate:Clone()
	templateClone.Text = text
	templateClone.Visible = true
	templateClone.Parent = visualText

	-- Increment the template's layout order.
	terminalTemplate.LayoutOrder += 1
end

-- Command Functions --
local function helpCommand()

	-- Use the help text of each command to display how to use it.
	for _, command in pairs(commands) do

		-- Hide elevated commands.
		if command.accessLevel > accessLevel+1 then
			continue
		end
		createTerminalItem("  - " .. command.name .. " (L" .. command.accessLevel .. ") - " .. command.helpText)
	end

	createTerminalItem("")
end

local function disableElevatorSecurityCommand()

	-- Update the status GUI itself.
	progressStatusText.Text = "Inactive"
	progressStatusText.TextColor3 = correctTextColor
	progressLabelText.TextColor3 = correctTextColor

	--- Update progress.
	elevatorProgress:SetAttribute("LockDisabled", true)

	-- Show the user that something has happend.
	createTerminalItem("Elevator security has been disabled.")
	createTerminalItem("")
end

local function elevateCommand()

	-- Allow the user to run elevated commands and elevate the terminal.
	canUseElevatedCommands = true
	accessLevel = 5

	-- Thematic text.
	createTerminalItem("Sufficient clearance. Elevating terminal...")
	task.wait(.2)
	createTerminalItem("Terminal access successfully elevated. Access level is now 5.")
	task.wait(.2)
	createTerminalItem("Welcome, root. Type \"Help\" to view new commands.")
	task.wait(.2)
	createTerminalItem("")
end

local function unlockAdministrationCommand()

	if not adminUnlocked then

		-- Toggle the flag.
		adminUnlocked = true

		-- Update the quest progress.
		adminProgress:SetAttribute("securityDisabled", true)

		-- Thematic text.
		createTerminalItem("Sufficient clearance. Disabling administration security override...")
		task.wait(.5)
		createTerminalItem("Administration security successfully overridden.")
		createTerminalItem('<font color="#ff2c2c"> Good luck.</font>')
		createTerminalItem("")

		-- Dialog
		dialogEvent:Fire(adminLockDisabledDialog, Enum.Font.Gotham, 3, true)
	else
		dialogEvent:Fire("~!~Fade~Nothing seems to happen.~ ", Enum.Font.Gotham, 3, true)
	end
end

-- Event Functions --
local function checkCommandInput(enterPressed: boolean?)

	-- Return if the user didn't press enter.
	if not enterPressed then
		return
	end
	
	-- Get the input command.
	local commandEntered = string.lower(commandInput.Text)
	local command = commands[commandEntered]

	-- Display and clear input.
	createTerminalItem("usr> " .. commandEntered)
	commandInput.Text = ""
	
	-- Don't scren over muscle memory for the incorrect spelling.
	if commandEntered == "dissableelevatorsecurity" then
		command = commands.disableelevatorsecurity
	end
	
	-- Check if the command entered is valid.
	if not command then

		-- Display invalid command text and reset input text.
		createTerminalItem("\"" .. commandEntered .. "\" is not a recognized command.")
		createTerminalItem("")

		-- Return.
		return
	end

	-- Return if the player has insufficient clearance.
	if accessLevel < command.accessLevel then

		-- Display invalid command text, reset input text, and return.
		createTerminalItem("Insufficient clearance to run \"" .. commandEntered .. "\".")
		createTerminalItem("")
		commandInput.Text = ""
		return
	end

	if command == commands["help"] then
		helpCommand()
	end

	if command == commands["accesslevel"] then
		createTerminalItem("This terminal currently as an access level of " .. accessLevel)
		createTerminalItem("")
	end

	if command == commands["disableelevatorsecurity"] then
		disableElevatorSecurityCommand()
	end

	if command == commands["unlockadministration"] then
		unlockAdministrationCommand()
	end

	if command == commands["elevate"] then
		elevateCommand()
	end
end




--[[---------------------------------------------------------------------
PASSCODE
--]]---------------------------------------------------------------------
---- Objects ----
local helpSound = soundService:WaitForChild("PuzzleHelpDialog")

---- Settings ----
local autoSolveTimeSeconds = 30 * 60
local helpDialog = "~!~SlowFade~Type ~~!~SmallWave~DisableElevatorSecurity ~~!~SlowFade~into the terminal. ~"

local passwordLength = 6
local possibleDigits = {
	'!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '=', '+',
	'B', 'C', 'G', 'L', 1, 2, 3, 4, 5, 6, 7, 8, 9, 0
}

local digitColors = {
	[1] = Color3.fromRGB(255, 70, 70),
	[2] = Color3.fromRGB(255, 121, 43),
	[3] = Color3.fromRGB(255, 239, 120),
	[4] = Color3.fromRGB(94, 255, 82),
	[5] = Color3.fromRGB(93, 220, 255),
	[6] = Color3.fromRGB(177, 99, 255)
}

local digitColorNames = {
	[1] = "Red",
	[2] = "Orange",
	[3] = "Yellow",
	[4] = "Green",
	[5] = "Blue",
	[6] = "Purple"
}

-- Flags --
local correctPasswordEntered = false

-- Storage --
local password = "######" -- Filler password

local function generatePasscode(): string

	-- Create aa placeholder variable for the password.
	local password = ""

	-- Get all possible password locations.
	local digitLocations = digitLocationsFolder:GetChildren()

	-- Grab X number of possible digits.
	for i=1, passwordLength, 1 do

		-- Get a random new digit.
		local newDigit = possibleDigits[math.random(1, #possibleDigits)]

		-- Grab a random location.
		local randomLocationNum = math.random(1, #digitLocations)
		local randomLocation = digitLocations[randomLocationNum]

		-- Clone the digit UI.
		local digitUIClone = digitUI:Clone()
		digitUIClone.Container["Digit Text"].Text = newDigit
		digitUIClone.Container["Digit Text"].TextColor3 = digitColors[i]

		-- If the digit text is on a computer, then make it glow.
		if randomLocation.Name == "Computer" then
			digitUIClone.LightInfluence = 0
			digitUIClone.Brightness = 5
			digitUIClone.Face = Enum.NormalId.Left
		end

		-- Make it possible for colorblind people to play BU.
		local colorClickDetector = Instance.new("ClickDetector")
		colorClickDetector.MaxActivationDistance = 10
		colorClickDetector.Parent = randomLocation

		local flavorText = digitColorNames[i]
		colorClickDetector.MouseClick:Connect(function ()
			dialogEvent:Fire("~!~Fade,Color=#" .. digitColors[i]:ToHex() .. "~\"".. flavorText .. "\" ~ ", Enum.Font.SpecialElite, 2)
		end)

		digitUIClone.Parent = randomLocation

		-- Prevent multiple digits from occupying the same location.
		table.remove(digitLocations, randomLocationNum)

		-- Add the new digit to the total password.
		password = password .. newDigit
	end

	--print("Password: " .. password)

	-- Return the result
	return password
end

local function enteredCorrectPassword()

	-- Prevent the password input from being changed.
	passwordInput.Interactable = false

	-- Display correct password text.
	createTerminalItem(" ")
	createTerminalItem("Welcome usr:")
	createTerminalItem("Type \"help\" to view all commands.")

	-- Show the input line.
	inputLine.Visible = true
	inputLine.Interactable = true

	-- Toggle flags.
	correctPasswordEntered = true

	-- Link up events.
	commandInput.FocusLost:Connect(checkCommandInput)
end

local function passwordEnteredCorrectly(enterPressed: boolean)

	-- Return if the user didn't press enter.
	if not enterPressed or correctPasswordEntered then
		return
	end

	-- If the password is incorrect, say so.
	if passwordInput.Text ~= password then

		-- Display failure text.
		createTerminalItem("Enter password for usr: " .. passwordInput.Text)
		createTerminalItem("Incorrect password, try again.")
		createTerminalItem(" ")

		-- Move password and template text forwards.
		passwordEnter.LayoutOrder += 3
		-- terminalTemplate.LayoutOrder += 1

		-- Clear current password text.
		passwordInput.Text = ""

		-- Reselect the input.
		passwordInput:CaptureFocus()
		return
	end

	-- The player entered the correct password.
	enteredCorrectPassword()
end

local function delayedHelp() -- If the player takes too long, solve the puzzle.

	if not correctPasswordEntered then

		-- Solve the puzzle.
		enteredCorrectPassword()
		createTerminalItem("[System]: Type '" .. commands.dissableelevatorsecurity.name .. "' to progress. ")

		-- Play the help sound.
		helpSound:Play()
		helpSound.Ended:Wait()

		dialogEvent:Fire(helpDialog, Enum.Font.Gotham, 10, true)
	end
end

passwordInput.FocusLost:Connect(passwordEnteredCorrectly)




--[[---------------------------------------------------------------------
DECRYPTION
--]]---------------------------------------------------------------------
--- Settings ----
local maxTime = 15
local maxStages = 5
local stage = 0

local sliderOffset = -0.025
local numTextInputs = 20

local grableChars = {
	'n','u','l','v','o','i','d','e','a','t','h',
	1,2,3,4,5,6,7,8,9,0,
	'!', '@','#','$','%','^','&','*','(',')', ' '
}
local realText = {
	"Void",
	"Nill",
	"Null",
	"Broken",
	"Password",
	"sudo rm -a"
}

local sliderDistance = math.abs(sliderPoint2.CFrame.X - sliderPoint.CFrame.X)

local correctElementText = "Noise"

---- Storage ----
local correctSliderNum -- The "level the slider must be moved to.
local correctStage = math.random(1, 10)
local sliderStage = 0
local correctStage = 1

local timeLeft = maxTime

---- Functions ----
-- Utility --
local function getGarble(length: number): string

	local finalString = ""

	for i=0, length, 1 do
		finalString = finalString .. grableChars[math.random(1, #grableChars)] 	
	end

	return finalString
end

-- GUI --
local function updateMinigame()

	-- Update the each GUI element.
	for _, garbleElement in ipairs(decryptInput:GetChildren()) do

		if not garbleElement:IsA("TextButton") then
			continue
		end

		-- Change the color and text of each button based on if it is the correct scene and if they are the correct text label.
		if garbleElement.Name == "Garble" then
			garbleElement.Text = getGarble(10)

			if garbleElement.TextColor3 == correctTextColor then
				garbleElement.TextColor3 = wrongColor
			end
		elseif garbleElement.Name == correctElementText then

			if sliderStage == correctStage then

				-- Change text
				garbleElement.Text = realText[math.random(1, #realText)]

				-- Change color
				tweenService:Create(garbleElement, quickFade, {
					TextColor3 = correctTextColor
				}):Play()
			else

				-- Change text
				garbleElement.Text = getGarble(10)

				-- Change Color 
				tweenService:Create(garbleElement, slowFade, {
					TextColor3 = wrongColor
				}):Play()			
			end
		end
	end
end

local function updateSlider(forcedStage: number?) 
	local mousePos = mouse.Hit 
	local relativeCFrame = sliderPoint.CFrame:ToObjectSpace(mousePos) 
	local sliderX = relativeCFrame.X / sliderDistance -- Allow only 10 slider stages. 

	local sliderRounded = math.clamp(math.round((sliderX) * 10), 0, 10) -- Clamp the input between the different stages. 
	sliderX = math.clamp(sliderX + sliderOffset, 0, 1)

	-- Force the slider to a specific stage. 
	if forcedStage then 
		sliderX = forcedStage 
	end

	if sliderRounded ~= sliderStage or forcedStage then 
		sliderStage = sliderRounded updateMinigame() 
	end 

	-- Update the GUI. 
	sliderOverlay.Size = UDim2.new(sliderX - sliderOffset, 0, 1, 0) sliderKnob.Position = UDim2.new(sliderX, 0, 0.5, 0)
end

-- Game Loop --
local function toggleLooseEffects()

	-- Show the access denied GUI.
	tweenService:Create(accessDenied, quickFade, {
		GroupTransparency = 0
	}):Play()

	-- Play SFX

	-- Hide the access denied GUI
	task.wait(quickFade.Time)
	tweenService:Create(accessDenied, superSlowFade, {
		GroupTransparency = 1
	}):Play()
end

local function toggleWinEffect()

	-- Temporarily disable the close button.
	closeButton.Interactable = false

	-- Make the minigame appear green to signify success.
	tweenService:Create(decrypt, slowFade, {
		GroupColor3 = Color3.fromRGB(47, 255, 0)
	}):Play()

	tweenService:Create(closeButton, slowFade, {
		TextTransparency = 1
	}):Play()
	closeButton.TextColor3 = commandInput.TextColor3

	-- Wait a bit
	task.wait(2)

	-- Hide and show each GUI element.
	tweenService:Create(decrypt, slowFade, {
		GroupTransparency = 1
	}):Play()
	tweenService:Create(login, slowFade, {
		GroupTransparency = 0
	}):Play()
	tweenService:Create(closeButton, slowFade, {
		TextTransparency = 0
	}):Play()

	-- Toggle the minigame that is active.
	decryptActive = false
	terminalActive = true

	-- Toggle the intractability of the elements.
	login.Interactable = true
	decrypt.Interactable = false
	closeButton.Interactable = true

	-- Possible delayed help with the terminal passcode.
	task.delay(autoSolveTimeSeconds, delayedHelp)
end

local function getRandomTextButton(parent: Instance)

	local children = parent:GetChildren()
	local randomIndex = math.random(1, #children)
	local randomChild = children[randomIndex]

	if randomChild:IsA("TextButton") then
		return randomChild
	else
		return getRandomTextButton(parent)
	end
end

local function setupRound()

	-- Clear existing correct answers.
	for _,textButton in ipairs(decryptInput:GetChildren()) do

		-- Skip non-textbutton instances.
		if not textButton:IsA("TextButton") then
			continue
		end

		textButton.Name = "Garble"
	end	

	-- Get a random special GUI.
	local specialGUIElement = getRandomTextButton(decryptInput)
	specialGUIElement.Name = correctElementText

	-- Setup the correct stage --
	correctStage =  math.random(0, 10)
end

local function checkIfCorrect(name)

	-- Go to the next stage if the correct button was pressed. Otherwise, go back to the first stage.
	if name == correctElementText and sliderStage == correctStage then
		stage += 1
		return true
	else
		stage = 0
		return false
	end
end

-- Events --
sliderKnob.Activated:Connect(function ()
	sliderDown = true
end)

sliderOverlay.MouseEnter:Connect(function ()
	mouseTouchingOverlay = true
end)

sliderOverlay.MouseLeave:Connect(function ()
	mouseTouchingOverlay = false
end)

sliderBody.MouseEnter:Connect(function ()
	mouseTouchingSlider = true
end)

sliderBody.MouseLeave:Connect(function ()
	mouseTouchingSlider = false
end)

userInputService.InputBegan:Connect(function (input)

	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and (mouseTouchingSlider or mouseTouchingOverlay) then

		-- The mouse button is now down.
		mouseDown = true

		-- Wait until the player releases their mouse to stop dragging the slider.
		repeat
			updateSlider()
			task.wait()
		until not mouseDown
	end
end)

userInputService.InputEnded:Connect(function (input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

		-- The mouse button is now up.
		mouseDown = false

		-- Toggle the slider.
		sliderDown = false
	end
end)




--[[---------------------------------------------------------------------
ELEVATED CLEARANCE
--]]---------------------------------------------------------------------
-- Objects --
local elevatedClearanceFolder = quests:WaitForChild("Elevated Clearance")
local blackcard = elevatedClearanceFolder:WaitForChild("Blackcard")
local blackcardMain = blackcard:WaitForChild("Card")
local bar = blackcardMain:WaitForChild("MeshPart")
local blackcardPrompt = blackcardMain:WaitForChild("ProximityPrompt")

local function elevateClearanceEvent()

	-- Increase the access level.
	accessLevel = 2

	-- Disable the blackcard prompt.
	blackcardPrompt.Enabled =  false

	-- Fade the keycard away.
	tweenService:Create(blackcardMain, fadeTweenInfo, {
		Transparency = 1
	}):Play()

	tweenService:Create(bar, fadeTweenInfo, {
		Transparency = 1
	}):Play()
end

-- Events --
elevateEvent.OnClientEvent:Once(elevateClearanceEvent)




--[[---------------------------------------------------------------------
CAMERA FUNCTIONALITY
--]]---------------------------------------------------------------------
-- Modules --
local controls = require(localPlr.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

-- Objects --
local camera = workspace.CurrentCamera
local terminalCameraPose = computerQuest:WaitForChild("CameraPose")

local triggerPart = computerQuest:WaitForChild("Trigger")
local trigger = triggerPart:WaitForChild("ProximityPrompt")

-- Storage -- 
local oldCameraCFrame = CFrame.new(0, 0, 0)
local character

local function toggleDecryption(isActive: boolean)

	local targetTransparency
	if isActive then

		-- Show the GUI.
		targetTransparency = 0

		-- Setup the round again.
		setupRound()

		-- The minigame is now active.
		minigameActive = true
		decrypt.Interactable = true
	else

		-- Hide the GUI.
		targetTransparency = 1
		toggleLooseEffects()

		-- Reset stages and timer.
		stage = 0	
		timeLeft = maxTime

		-- Update the rounds text GUI.
		roundText.Text = stage .. "/" .. maxStages

		-- The minigame is now inactive.
		minigameActive = false
		decrypt.Interactable = false
	end

	-- Tween the GUI in/out
	tweenService:Create(decrypt, slowFade, {
		GroupTransparency = targetTransparency
	}):Play()
end

local function toggleTerminal(isActive: boolean)

	local targetTransparency
	if isActive then

		-- Show the GUI.
		targetTransparency = 0

		-- Allow player interaction.
		login.Interactable = true
	else

		-- Hide the GUI.
		targetTransparency = 1

		-- Prevent player interaction.
		login.Interactable = false
	end

	-- Tween the GUI in/out
	tweenService:Create(login, slowFade, {
		GroupTransparency = targetTransparency
	}):Play()
end

local function toggleActiveView(isActive: boolean)

	-- Get the character if they do not exist.
	if not character then
		character = localPlr.Character
	end

	-- Handle other GUI elements.
	if decryptActive then
		toggleDecryption(isActive)
	elseif terminalActive then
		toggleTerminal(isActive)
	end

	-- Force the player to walk upon the camera changing.
	local xButtonTargetTransparency
	if isActive then

		-- Disable the proximity prompt.
		trigger.Enabled = false

		-- Force the player to walk to prevent unexpected behavior.
		forceStateBindableEvent:Fire(movementStateEnum.walking)
		toggleVFXBindableEvent:Fire(false)
		runsService.RenderStepped:Wait()

		-- Store the old camera CFrame
		oldCameraCFrame = camera.CFrame

		-- Adjust the camera.
		camera.CameraType = Enum.CameraType.Scriptable

		-- Move the camera to the desired position.
		tweenService:Create(camera, slowFade, {
			CFrame = terminalCameraPose.CFrame
		}):Play()

		-- Show the X button.
		xButtonTargetTransparency = 0
		closeButton.Interactable = true

		-- Disable the player's controls.
		controls:Disable()
	else

		-- Tween back to the player's camera.
		tweenService:Create(camera, slowFade, {
			CFrame = oldCameraCFrame
		}):Play()

		-- Wait for the tween to complete, then restore camera control.
		task.wait(slowFade.Time)
		camera.CameraType = Enum.CameraType.Custom
		toggleVFXBindableEvent:Fire(true)

		-- Hide the X button.
		xButtonTargetTransparency = 1
		closeButton.Interactable = false

		-- Enable the player's controls.
		controls:Enable()
		task.delay(slowFade.Time, function () -- Delayed to prevent weird tween functionality.
			trigger.Enabled = true
		end)
	end

	-- Hide/show the close button.
	tweenService:Create(closeButtonContainer, slowFade, {
		GroupTransparency = xButtonTargetTransparency
	}):Play()

	-- Toggle other player GUI and this GUI.
	toggleGUIBindableEvent:Fire(not isActive)
	gui.Active = isActive
end

-- Event Functions --
local function playerDied()
	if gui.Active then
		toggleActiveView(false)
	end
end

-- Events --
deathEvent.OnClientEvent:Connect(playerDied)

trigger.Triggered:Connect(function ()
	toggleActiveView(true)
end)

closeButton.Activated:Connect(function ()
	toggleActiveView(false)
end)




--[[---------------------------------------------------------------------
GENERAL
--]]---------------------------------------------------------------------
-- GUI Setup Functions --
local function setupGame()

	-- Clone all of the 
	for numClones=0, numTextInputs-2, 1 do

		local clone = garble:Clone()
		clone.Parent = garble.Parent
	end

	-- Loop through all of the text inputs and setup them up with events.
	for _,textButton in ipairs(decryptInput:GetChildren()) do

		-- Skip non-textbutton instances.
		if not textButton:IsA("TextButton") then
			continue
		end

		textButton.Activated:Connect(function ()

			-- Check if the button is correct.
			local correct = checkIfCorrect(textButton.Name)

			-- Tween the button's color based on whether or not the player selected it correctly.
			if correct then
				textButton.TextColor3 = correctSelectedColor
			else
				textButton.TextColor3 = wrongSelectedColor
			end

			tweenService:Create(textButton, fadeTweenInfo, {
				TextColor3 = wrongColor
			}):Play()

			-- Update the rounds text GUI.
			roundText.Text = stage .. "/" .. maxStages

			-- Logic for if the player wins or looses.
			if stage < maxStages then

				-- Reset the timer if the player lost. Otherwise, add 3 seconds to the timer.
				if stage == 0 then
					timeLeft = maxTime
					toggleLooseEffects()
				else
					timeLeft += 3
				end

				-- Re setup the round.
				setupRound()
			else

				-- The minigame is no longer active.
				minigameActive = false

				-- Toggle the win effects and allow the terminal to be used.
				toggleWinEffect()
			end

			-- Refresh the minigame text
			updateMinigame()
		end)
	end
end

local function periodic(deltaTime)

	-- Update the slider if told to do so.
	if sliderDown then
		updateSlider()
	end

	if minigameActive then

		-- Update the time left.
		timeLeft -= deltaTime
		timeText.Text = math.floor(timeLeft) .. "s"

		-- Handle loss due to timer.
		if timeLeft <= 0 then

			-- Reset stages and timer.
			stage = 0	
			timeLeft = maxTime

			-- Update the rounds text GUI.
			roundText.Text = stage .. "/" .. maxStages

			-- Toggle the loss effects.
			toggleLooseEffects()

			-- Setup the round again.
			setupRound()
		end
	end
end

-- Events --
runsService.Heartbeat:Connect(periodic)

-- Setup --
setupGame()
setupRound()
updateSlider(0)
task.wait(3) -- Wait a bit to let everything load in.
password = generatePasscode() -- Update the password.