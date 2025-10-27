-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.5, Enum.EasingStyle.Quad)

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local configModules = modules:WaitForChild("Configs")
local highlightPreset = require(configModules:WaitForChild("HighlightPreset"))
local enumModules = modules:WaitForChild("Enums")
local highlightMode = require(enumModules:WaitForChild("HighlightMode"))

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local dialogEvents = bindableEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

local interactionEvents = bindableEvents:WaitForChild("Interaction")
local highlightEvent = interactionEvents:WaitForChild("HighlightEvent")
-- Objects --
local quests = workspace:WaitForChild("Quests")

local generatorQuest = quests:WaitForChild("Generator Quest")
local leverBase = generatorQuest:WaitForChild("Lever")

local spawnLocationGroup = generatorQuest:WaitForChild("Spawn Locations")
local spawnLocations = spawnLocationGroup:GetChildren()

local activeLeversFolder = generatorQuest:WaitForChild("Active Levers")

local elevatorQuest = quests:WaitForChild("Elevator")
local questProgress = elevatorQuest:WaitForChild("Progress")

local questComputer = elevatorQuest:WaitForChild("Computer")
local screen = questComputer:WaitForChild("Screen")
local computerGUI = screen:WaitForChild("StatusGUI")
local guiContainer = computerGUI:WaitForChild("Frame")

-- Settings --
local dialogBase = "~!~Fade~ %s / %s generators powered. ~"
local dialogFont = Enum.Font.Gotham
local dialogAppearanceDuration = 3

local requiredLevers = 3
local spawnedLevers = 5
local activatedColor = Color3.fromRGB(86, 255, 56)

local rotationAmountDegrees = 165

-- Storage --
local activeLevers = {}
local numLeversFlipped = 0

-- Functions --
local function clearUnusedLevers()
	for _,lever in ipairs(activeLevers) do
		lever:Destroy()
	end
end

local function leverFlipped(leverClone)
	
	-- Setup the lever and compute the spatial offset.
	local leverModel = leverClone:WaitForChild("Lever")
	leverModel.PivotOffset = leverModel:GetPivot()
	
	local leverModelOffset = leverModel.PivotOffset:ToObjectSpace(leverModel.CFrame)
	
	-- Flip the lever.
	local pivotTween = tweenService:Create(leverModel, defaultTween, {
		PivotOffset = leverModel.PivotOffset * CFrame.Angles(0, 0, math.rad(rotationAmountDegrees))
	})
	
	pivotTween:Play()
	while pivotTween.PlaybackState == Enum.PlaybackState.Playing do
		leverModel.CFrame = leverModel.PivotOffset:ToWorldSpace() * leverModelOffset
		task.wait()
	end
	
	-- Increment the levers flipped by 1.
	numLeversFlipped += 1
	questProgress:SetAttribute("GeneratorsActive", numLeversFlipped)
	
	-- Update the GUI.
	local affectedText = guiContainer:FindFirstChild("Gen"..tostring(numLeversFlipped))
	if not affectedText then
		return
	end
	
	-- Update the GUI.
	affectedText.Status.Text = "Active"
	affectedText.Status.TextColor3 = activatedColor
	affectedText.Label.TextColor3 = activatedColor
	
	-- Display dialog to communicate progress.
	dialogEvent:Fire(string.format(dialogBase, numLeversFlipped, requiredLevers), dialogFont, dialogAppearanceDuration, true)
	
	-- End the puzzle if all the levers have been flipped.
	if numLeversFlipped == requiredLevers then
		clearUnusedLevers()
		script.Enabled = false -- Disable the script.
	end
end

-- Highlight Events --
local function mouseEnter(lever)
	highlightEvent:Fire(lever, highlightMode.Show, highlightPreset.Default)
end

local function mouseLeave(lever)
	highlightEvent:Fire(lever, highlightMode.Hide)
end


local function spawnLever()
	
	-- If no more levers can be spawned, return.
	if #spawnLocations == 0 then
		return
	end
	
	-- Grab a random spawn location.
	local spawnIndex = math.random(1, #spawnLocations)
	local spawnLocation = spawnLocations[spawnIndex]
	
	-- Clone the lever.
	local leverClone = leverBase:Clone()
	leverClone:PivotTo(spawnLocation.CFrame)
	leverClone.Parent = activeLeversFolder
	
	-- Link up the clicking the lever to powering on a generator.
	local hitbox = leverClone:WaitForChild("Hitbox")
	local clickDetector = hitbox:WaitForChild("ClickDetector")
	local leverSound = hitbox:WaitForChild("Flip")
	clickDetector.MouseClick:Once(function ()
		
		-- Disable the click detector.
		clickDetector:Destroy()
		leverSound:Play()
		
		-- Remove the lever from the list of active levers.
		table.remove(activeLevers, table.find(activeLevers, leverClone))
		
		-- The lever has been flipped.
		mouseLeave(leverClone)
		leverFlipped(leverClone)
	end)
	
	-- Highlight Events --
	clickDetector.MouseHoverEnter:Connect(function (plr)
		mouseEnter(leverClone)
	end)
	clickDetector.MouseHoverLeave:Connect(function (plr)
		mouseLeave(leverClone)
	end)
	
	-- Add the lever to the list of active levers.
	table.insert(activeLevers, leverClone)
	
	-- Prevent the spawn location from being used again.
	table.remove(spawnLocations, spawnIndex)
end

-- Setup the puzzle by setting up the levers when the game starts.
for i=0, spawnedLevers, 1 do
	spawnLever()
end

-- Clear out the spawn locations.
spawnLocationGroup:ClearAllChildren()