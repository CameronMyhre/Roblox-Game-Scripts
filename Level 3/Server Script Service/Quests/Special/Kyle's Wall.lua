-- Services --
local badgeService = game:GetService("BadgeService")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local hiddenWallQuest = quests:WaitForChild("Hidden Area - Kyle")
local hiddenWall = hiddenWallQuest:WaitForChild("FadingWall")
local proximityPrompt = hiddenWall:WaitForChild("ProximityPrompt")

-- Settings --
local badgeId = 2147738920

-- Functions --
local function promptActivated(player: Player)
	
	-- Check if the player has the badge. If not, give them the badge.
	if not badgeService:UserHasBadgeAsync(player.UserId, badgeId) then
		badgeService:AwardBadge(player.UserId, badgeId)
	end
end

-- Events --
proximityPrompt.Triggered:Connect(promptActivated)
hiddenWall.Touched:Connect(function (part)
	
	-- If the part that touched the wall isn't a player, then return.
	if not part.Parent:FindFirstChild("Humanoid") then
		return
	end
	
	local player = game.Players:GetPlayerFromCharacter(part.Parent)
	if not player then
		return
	end
	
	promptActivated(player)
end)