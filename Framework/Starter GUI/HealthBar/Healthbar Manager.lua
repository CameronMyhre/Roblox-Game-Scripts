-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local guiFadeTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local players = game:GetService("Players")
local localPlr = players.LocalPlayer

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local guiBindableEvents = bindableEvents:WaitForChild("GUI")
local toggleGUIBindableEvent = guiBindableEvents:WaitForChild("ToggleGUI")

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local guiRemoteEvents = remoteEvents:WaitForChild("GUI")
local toggleGUIEvent = guiRemoteEvents:WaitForChild("ToggleGUI")

local playerEvents = remoteEvents:WaitForChild("Player")
local onDeathEvent = playerEvents:WaitForChild("DeathEvent")

-- Objects --
local character = localPlr.Character
local healthStats

-- GUI --
local gui = script.Parent
local guiGroup = gui:WaitForChild("CanvasGroup")
local overlay = guiGroup:WaitForChild("Overlay")
local healthText = guiGroup:WaitForChild("HealthText")
local overhealOverlay = guiGroup:WaitForChild("Overlay=Overheal")

local healthEffects = gui:WaitForChild("Full Screen Health Effects")
local lowHealthOverlay = healthEffects:WaitForChild("LowHealthEffect")
local overhealOverlayEffect = healthEffects:WaitForChild("OverhealEffect")

-- Settings -- 
local maxWidth = .99
local minOverhealTransparency = 0.8
local minLowHealthTransparency = 0.25
local lowHealthHPPercentThreshold = 0.4

-- Flags --
local overheaalVisible

-- Functions --
local function roundTo(number, decimalPlaces : number)
	return tonumber(string.format("%." .. decimalPlaces .. "f", number))
end

local function updateOverhealGUI(percentOverheal: number)

	-- Calculate the target size.
	local targetSize = UDim2.new(maxWidth * percentOverheal, 0, 1, 0)

	-- Tween the overlay into position.
	tweenService:Create(overhealOverlay, defaultTween, {
		Size = targetSize,
		ImageTransparency = 0
	}):Play()

	tweenService:Create(overhealOverlayEffect, defaultTween, {
		ImageTransparency = math.max(minOverhealTransparency, (1-(minOverhealTransparency * percentOverheal)))
	}):Play()
	
	-- Overheal is visible.
	overheaalVisible = true
end

local function updateRegularGUI(percentHealth: number)

	-- Calculate the target size.
	local targetSize = UDim2.new(maxWidth * percentHealth, 0, .9, 0)
	
	-- Tween the overlay into position.
	tweenService:Create(overlay, defaultTween, {
		Size = targetSize
	}):Play()
	

	if percentHealth < lowHealthHPPercentThreshold then
		tweenService:Create(lowHealthOverlay, defaultTween, {
			ImageTransparency = math.max(minLowHealthTransparency, ((percentHealth/lowHealthHPPercentThreshold)))
		}):Play()
	else
		tweenService:Create(lowHealthOverlay, defaultTween, {
			ImageTransparency = 1
		}):Play()
	end
end

local function updateGUI()
	
	local currentHealth = healthStats:GetAttribute("Health")
	local maxHealth = healthStats:GetAttribute("MaxHealth")
	
	-- Calculate the percent health.
	local percentHealth = math.max(0, math.min(1, currentHealth / maxHealth))
	updateRegularGUI(percentHealth)
	
	-- Calculate the text.
	local text = roundTo(currentHealth, 1) .. "/" .. roundTo(maxHealth, 1)
	healthText.Text = text
	
	-- Handle overheal
	if currentHealth > maxHealth then
		
		-- Calculate the % overheal.
		local maxoverheal = healthStats:GetAttribute("MaxOverheal")
		local percentOverheal = math.min(1, (currentHealth-maxHealth) / maxoverheal)
		
		-- Tween the overheal GUI.
		updateOverhealGUI(percentOverheal)
	elseif overheaalVisible then

		-- Tween the overlay away.
		local targetSize = UDim2.new(0, 0, 1, 0)
		
		-- Tween the overlay into position.
		tweenService:Create(overhealOverlay, defaultTween, {
			Size = targetSize,
			ImageTransparency = 1
		}):Play()
		
		tweenService:Create(overhealOverlayEffect, defaultTween, {
			ImageTransparency = 1
		}):Play()
		
		-- Overheal GUI is no longer visible.
		overheaalVisible = false
	end
end

-- Event Functions --
local function toggleGUI(toActive: boolean)

	local targetTransparency
	if toActive then
		targetTransparency = 0 -- Visible GUI.
	else
		targetTransparency = 1 -- Invisible GUI.
	end

	-- Fade the GUI in/out.
	tweenService:Create(guiGroup, guiFadeTween, {
		GroupTransparency = targetTransparency
	}):Play()
end

-- Redundant failsafe.
while not character do
	character = localPlr.Character
	task.wait()
end

-- Events --
healthStats = character:WaitForChild("Health Stats")
healthStats.AttributeChanged:Connect(updateGUI)

toggleGUIEvent.OnClientEvent:Connect(toggleGUI)
toggleGUIBindableEvent.Event:Connect(toggleGUI)

-- Ensure that the GUI remains true upon death.
onDeathEvent.OnClientEvent:Connect(function ()
	local currentHealth = healthStats:GetAttribute("Health")
	if not (currentHealth <= 0) then
		healthStats:SetAttribute("Health", 0)
	end
end)