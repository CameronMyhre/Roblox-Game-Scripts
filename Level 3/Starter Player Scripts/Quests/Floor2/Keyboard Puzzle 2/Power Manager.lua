-- Services --
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

local tweenService = game:GetService("TweenService")
local fadeTween = TweenInfo.new(0.5, Enum.EasingStyle.Quad)

local soundService = game:GetService("SoundService")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local keycardQuest2Folder = quests:WaitForChild("Keycard Quest 2")

local breakerBox = keycardQuest2Folder:WaitForChild("Power Box B")
local buttons = breakerBox:WaitForChild("Buttons")
local interactionPoint = buttons:WaitForChild("InteractionPoint")
local proximityPrompt = interactionPoint:WaitForChild("ProximityPrompt")
local clickSound = buttons:WaitForChild("power-cut-101047")

local keycardScanner = keycardQuest2Folder:WaitForChild("Keycard_Scanner")
local keycardLight = keycardScanner:WaitForChild("Light")

local door = keycardQuest2Folder:WaitForChild("Electrical Clean Door")
local doorModel = door:FindFirstChild("DoorModel") or door:WaitForChild("DoorModel")
local doorPrimaryPart = doorModel.PrimaryPart
local clickDetector = doorPrimaryPart:FindFirstChild("ClickDetector") or doorPrimaryPart:WaitForChild("ClickDetector")

local lights = workspace:WaitForChild("Ceiling Lights")
local questRelevantLightFolder = lights:WaitForChild("Yellow Station Lights")

-- SFX --
local clickSound = buttons:WaitForChild("power-cut-101047")
local powerOut = soundService:WaitForChild("power-down-45784")

-- Flags --
local poweredDown = false

-- Functions --
local function toggleLights()
	
	-- Power off all of the lights.
	local questRelevantLights = questRelevantLightFolder:GetChildren()
	for _, light in ipairs(questRelevantLights) do
		
		local emissionPart = light:FindFirstChild("Emitter")
		if not emissionPart then
			continue
		end
		
		-- Fade the emission part to black.
		tweenService:Create(emissionPart, fadeTween, {
			Color = Color3.fromRGB(0, 0, 0)
		}):Play()
		
		-- Attempt to find a light beam. If one can be found, hide it.
		local lightBeam: Beam = emissionPart:FindFirstChild("Light Beam")
		if lightBeam then
			lightBeam.Enabled = false
		end
		
		-- Attempt to find a surface light. If one can be found, fade it away.
		local surfaceLight = emissionPart:FindFirstChild("SurfaceLight")
		if surfaceLight then
			tweenService:Create(surfaceLight, fadeTween, {
				Brightness = 0
			}):Play()
		end
		
		-- Attempt to find a light point where the point light is stored.
		local lightPoint = emissionPart:FindFirstChild("LightPoint")
		if lightPoint then
			
			-- Attempt to find a point light. If one can be found, fade it away.
			local pointLight = lightPoint:FindFirstChild("PointLight")
			if pointLight then
				tweenService:Create(pointLight, fadeTween, {
					Brightness = 0
				}):Play()
			end
		end
	end
	
	-- Toggle the keycard scanner's light.
	tweenService:Create(keycardLight, fadeTween, {
		Color = Color3.fromRGB(0, 0, 0)
	}):Play()
	
	-- Remove light objects.
	keycardLight:ClearAllChildren()
end

local function powerTripped(plr: Player)
	
	-- Check if the player is the local player and that power has not been tripped before.
	if plr ~= localPlr or poweredDown then
		return
	end
	
	-- Disable the proximity prompt.
	proximityPrompt.Enabled = false
	clickSound.TimePosition = 1.5
	clickSound:Play()
	task.wait(.8)
	powerOut:Play()
	
	-- Hide the lights.
	toggleLights()
	
	-- Update the door's activation distance.
	clickDetector.MaxActivationDistance = 5
	
	-- Prevent multiple activation.
	poweredDown = true
end

proximityPrompt.Triggered:Connect(powerTripped)