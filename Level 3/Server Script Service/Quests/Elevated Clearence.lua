-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local badgeService = game:GetService("BadgeService")
local collectionService = game:GetService("CollectionService")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local questEvents = remoteEvents:WaitForChild("Quest")
local elevateClearanceEvent = questEvents:WaitForChild("ElevateEvent")

local framework = replicatedStorage:WaitForChild("Framework")
local frameworkRemoteEvents = framework:WaitForChild("Remote Events")
local dialogEvents = frameworkRemoteEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local elevatedCredentialsQuest = quests:WaitForChild("Elevated Clearance")
local managerKeycard = elevatedCredentialsQuest:WaitForChild("Manager's Card")
local managerKeycardPart = managerKeycard:WaitForChild("Card")
local managerKeycardPrompt = managerKeycardPart:WaitForChild("ProximityPrompt")

local blackcard = elevatedCredentialsQuest:WaitForChild("Blackcard")
local blackcardPart = blackcard:WaitForChild("Card")
local blackcardPrompt = blackcardPart:WaitForChild("ProximityPrompt")

-- Settings --
local hasKeycardTag = "HasKeycard"
local badgeID = 2142997236

local dialogManagerKeycard = "~!~Fade~Blue Keycard acquired. You can now unlock blue keycard doors.~"
local dialogBlackcard = "~!~Fade~Terminal clearance raised to Level 2-try 'elevate' at a terminal to gain admin access.~"

-- Functions --
local function blackcardTriggered(plr: Player)
	
	-- If the player clipped in here, do nothing.
	if not collectionService:HasTag(plr, hasKeycardTag) then
		return
	end
	
	-- Give the badge if the player does not have it.
	if not badgeService:UserHasBadgeAsync(plr.UserId, badgeID) then
		badgeService:AwardBadge(plr.UserId, badgeID)
	end
	
	-- Fire the dialog.
	dialogEvent:FireClient(plr, dialogBlackcard, Enum.Font.Gotham, 3, true)
	
	-- Elevate the terminal.
	elevateClearanceEvent:FireClient(plr)
end

local function managerKeycardTriggered(plr: Player)
	
	-- Give the tag and dialog if the player does not have it.
	if not collectionService:HasTag(plr, hasKeycardTag) then
		collectionService:AddTag(plr, hasKeycardTag)
		
		-- Fire the dialog.
		dialogEvent:FireClient(plr, dialogManagerKeycard, Enum.Font.Gotham, 3, true)
	end
end

-- Events --
managerKeycardPrompt.Triggered:Connect(managerKeycardTriggered)
blackcardPrompt.Triggered:Connect(blackcardTriggered)