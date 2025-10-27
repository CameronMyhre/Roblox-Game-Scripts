-- Services --
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

local userInputService = game:GetService("UserInputService")

-- Objects --
local character = localPlr.Character
local light = script:WaitForChild("MobileHelpLight")

-- Functions --
local function cloneLightIfOnMobile()

	-- If the user is on mobile, clone the light. They cannot equip and unequip lights as fast, so this makes things a bit easier on them.
	if userInputService.TouchEnabled and (not userInputService.MouseEnabled or not userInputService.KeyboardEnabled) then

		local head = character:FindFirstChild("Head")
		if not head then
			return
		end

		light.Parent = head
	end
end

-- Setup --
cloneLightIfOnMobile()