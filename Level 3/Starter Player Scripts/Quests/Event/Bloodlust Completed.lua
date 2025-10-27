-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(5, Enum.EasingStyle.Quad)

local lighting = game:GetService("Lighting")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local bloodlustEvents = remoteEvents:WaitForChild("Bloodlust")
local toggleTeleportVFX = bloodlustEvents:WaitForChild("ToggleTeleportVFX")

-- Objects --
local colorCorrection = lighting:WaitForChild("ColorCorrection")
local blur = lighting:WaitForChild("Blur")

-- Functions --
local function eventEnded()
	
	-- Tween the screen red.
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness = 1,
		TintColor = Color3.fromRGB(255, 0, 0)
	}):Play()
	
	-- Tween the blur to the max.
	tweenService:Create(blur, defaultTween, {
		Size = 25
	}):Play()
end

-- Events --
toggleTeleportVFX.OnClientEvent:Connect(eventEnded)