-- Services --
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(2, Enum.EasingStyle.Quad)

-- Objects --
local quests = workspace:WaitForChild("Quests")
local fadingWallQuest = quests:WaitForChild("Hidden Area - Kyle")
local hiddenWall = fadingWallQuest:WaitForChild("FadingWall")
local proximityPrompt = hiddenWall:WaitForChild("ProximityPrompt")

-- SFX --
local fadeSFX = hiddenWall:WaitForChild("FadeSFX")

-- Storage --
local mobileConnection

-- Functions --
local function fadeWall()
	
	-- Play the sound effect --
	fadeSFX:Play()
	
	-- Fade Wall --
	tweenService:Create(hiddenWall, defaultTween, {
		Transparency = 1
	}):Play()
	task.wait(defaultTween.Time)
	
	-- Disable collision.
	hiddenWall.CanCollide = false
	proximityPrompt.Enabled = false
	proximityPrompt:Destroy()
end

local function promptTriggered(plr: Player)
	
	-- If the player who triggered the prompt isn't the local player, then return.
	if plr ~= localPlr then
		return
	end
	
	fadeWall()
end

proximityPrompt.Triggered:Connect(promptTriggered)

-- Setup --
task.wait(10)
if userInputService.TouchEnabled and not userInputService.KeyboardEnabled then
	
	mobileConnection = hiddenWall.Touched:Connect(function (part)
		
		-- If the part that touched the wall isn't a player, then return.
		if not part.Parent:FindFirstChild("Humanoid") then
			return
		end
		
		local player = players:GetPlayerFromCharacter(part.Parent)
		if not player or player ~= localPlr then
			return
		end
		
		promptTriggered(player)
		mobileConnection:Disconnect()
	end)
end