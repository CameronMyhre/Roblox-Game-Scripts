-- Services --
local badgeService = game:GetService("BadgeService")
local players = game:GetService("Players")

-- Objects --
local badgeGivers = workspace:WaitForChild("Badge Givers")
local goldityRoomBadgeGiver = badgeGivers:WaitForChild("Goldity's Room")

-- Settings --
local badgeId = 3600355599323595

-- Functions --
local function partTouched(part)

	local possibleCharacter = part.Parent
	local possiblePlayer = players:GetPlayerFromCharacter(possibleCharacter)
	if not possiblePlayer then
		return
	end
	
	-- Check if the player has the badge. If not, give them the badge.
	if not badgeService:UserHasBadgeAsync(possiblePlayer.UserId, badgeId) then
		badgeService:AwardBadge(possiblePlayer.UserId, badgeId)
	end
end

-- Events --
goldityRoomBadgeGiver.Touched:Connect(partTouched)