-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(0.25,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut)

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")

-- Configurations.
local configs = modules:WaitForChild("Configs")
local presets = require(configs:WaitForChild("HighlightPreset"))

-- Enums.
local enums = modules:WaitForChild("Enums")
local highlightMode = require(enums:WaitForChild("HighlightMode"))

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")
local interactionEvents = bindableEvents:WaitForChild("Interaction")
local highlightBindableEvent = interactionEvents:WaitForChild("HighlightEvent")

-- Remote Events --
local remoteEvents = framework:WaitForChild("Remote Events")
local remoteInteractionEvents = remoteEvents:WaitForChild("Interaction")
local highlightEvent = remoteInteractionEvents:WaitForChild("HighlightEvent")

local playerEvents = remoteEvents:WaitForChild("Player")
local deathEvent = playerEvents:WaitForChild("DeathEvent")

-- Objects --
local highlight = script:WaitForChild("Interaction Highlight")

-- Storage --
local currentTween

-- Main Function --
local function toggle(part: Instance, mode: highlightMode.HighlightMode, preset: presets.HighlightPreset?)

	-- Verify that the given part is in fact an instance.
	if typeof(part) ~= "Instance" then
		warn("[Highlight] Ignoring toggle: invalid part", part)
		return
	end
	
	-- Provide a default preset.
	local tweenablePreset = preset
	if not preset then
		tweenablePreset = presets.Default
	end	
	
	if currentTween then
		currentTween:Cancel()
	end
	
	if mode == highlightMode.Show then
		
		-- Check if the previously attached part's highlight has tweened away.
		if highlight.Adornee and highlightMode.Adornee ~= part then
			toggle(highlight.Adornee, highlightMode.Hide)
		end
		
		-- Check if a highlight exists.
		local partHighlight = part:FindFirstChildOfClass("Highlight")
		local highlightSettings: presets.HighlightPreset
		if partHighlight and partHighlight.Enabled then
			
			-- Copy the important light settings.
			highlightSettings = {
				FillColor = partHighlight.FillColor,
				FillTransparency = partHighlight.FillTransparency,
				OutlineColor = partHighlight.OutlineColor,
				OutlineTransparency = partHighlight.OutlineTransparency
			}
			
			-- Destroy the preexisting highlight (if it isn't this script's highlight)
			if not (partHighlight == highlight) then
				partHighlight:Destroy()
			end
		else
			
			-- Start anew with colors and transparency
			highlightSettings = {
				FillColor = tweenablePreset.FillColor,
				FillTransparency = 1,
				OutlineColor = tweenablePreset.OutlineColor,
				OutlineTransparency = 1
			}
		end
		
		-- Update this highlight's settings to match any of the old settings.
		highlight.Adornee = part
		if highlightSettings then
			highlight.FillColor = highlightSettings.FillColor
			highlight.FillTransparency = highlightSettings.FillTransparency
			highlight.OutlineColor = highlightSettings.OutlineColor
			highlight.OutlineTransparency = highlightSettings.OutlineTransparency
		end
		
		-- Tween the highlight to the preset.
		currentTween = tweenService:Create(highlight, defaultTween, {
			FillColor = tweenablePreset.FillColor,
			FillTransparency = tweenablePreset.FillTransparency,
			OutlineColor = tweenablePreset.OutlineColor,
			OutlineTransparency = tweenablePreset.OutlineTransparency
		})
		
		-- Play the current tween.
		currentTween:Play()
		
	elseif mode == highlightMode.Hide then
		
		-- If the highlight clone is not attached to the part, then exit.
		if not (highlight.Adornee == part) then
			return
		end
		
		-- Create a clone of the highlight to fade away.
		local highlightClone = highlight:Clone()
		highlightClone.Parent = part
		debris:AddItem(highlightClone, defaultTween.Time)
		
		-- Remove the current Adornee from the highlight.
		highlight.Adornee = nil
		highlight.Parent = script
		
		-- Tween the new highlight away.
		tweenService:Create(highlightClone, defaultTween, {
			FillTransparency = 1,
			OutlineTransparency = 1
		}):Play()
	end
end

-- Events --
highlightEvent.OnClientEvent:Connect(toggle)
highlightBindableEvent.Event:Connect(toggle)
deathEvent.OnClientEvent:Connect(function ()
	
	-- Remove the currently active highlight if it exists.
	if not highlight.Adornee then
		return
	end
	
	toggle(highlight.Adornee, highlightMode.Hide)
end)

-- TODO: Add logic to disable highlight until respawn.