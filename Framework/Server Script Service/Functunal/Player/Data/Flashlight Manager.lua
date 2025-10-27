-- Services --
local players = game:GetService("Players")
local serverStorage = game:GetService("ServerStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
local badgeService = game:GetService("BadgeService")
local marketplaceService = game:GetService("MarketplaceService")

-- Bindable Events --
local framework = serverStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local datastoreEvents = bindableEvents:WaitForChild("Datastore")
local dataLoadedEvent = datastoreEvents:WaitForChild("DataLoaded")

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local remoteFlashlightEvents = remoteEvents:WaitForChild("Flashlight")
local equipFlashlightEvent = remoteFlashlightEvents:WaitForChild("EquipFlashlight")
local flashlightDataUpdatedEvent = remoteFlashlightEvents:WaitForChild("FlashlightDataUpdated") -- (kept for external use)

-- Remote Functions --
local remoteFunctions = remoteFramework:WaitForChild("Remote Functions")
local getFlashlightDataFunction = remoteFunctions:WaitForChild("GetFlashlightData")

-- Modules --
local modules = framework:WaitForChild("Modules")
local flashlightModules = modules:WaitForChild("Flashlight")
local flashlightDataType = require(flashlightModules:WaitForChild("FlashlightData"))
local flashlightRequirementTypes = require(flashlightModules:WaitForChild("FlashlightRequirementTypes"))

-- Settings --
local defaultFlashlight = flashlightDataType.regular

local plrDataFolderName = "plrData"
local equippedFlashlightValueName = "EquippedFlashlight"
local flashlightToolName = "Flashlight"

local groupIDUsed = 11725215

local plrDebounceSeconds = 0.2 -- Prevent large equip spam requests.

-- Storage (use dictionaries keyed by UserId for MP safety) --
local receivedDataOnce = {}          -- [userId] = lastRequestClock (throttled)
local lastFlashlightPayload = {}     -- [userId] = last formatted payload table
local equipDebounce = {}             -- [userId] = true while on cooldown

-- Caches for service lookups to reduce spam and hiccups in MP --
local badgeCache = {}                -- [userId] = { [badgeId] = true/false }
local gamepassCache = {}             -- [userId] = { [passId] = true/false }

-- Functions --
-- Utility Functions --
local function getEquippedFlashlightValue(plr: Player)
	-- Safe fetch of player's string value
	local plrDataFolder = plr:FindFirstChild(plrDataFolderName)
	if not plrDataFolder then
		return nil
	end

	local flashlightValue = plrDataFolder:FindFirstChild(equippedFlashlightValueName)
	if not flashlightValue then
		return nil
	end

	return flashlightValue
end

--[[
Returns the lowest number in an array.
]]
local function getLowestValueInTable(array: {number})
	local lowestNumber = math.huge
	for _, number in ipairs(array) do
		if number < lowestNumber then
			lowestNumber = number
		end
	end
	return lowestNumber
end

-- Safe service lookups with caching --
local function userHasBadge(userId: number, badgeId: number): boolean
	badgeCache[userId] = badgeCache[userId] or {}
	if badgeCache[userId][badgeId] ~= nil then
		return badgeCache[userId][badgeId]
	end
	local ok, has = pcall(badgeService.UserHasBadgeAsync, badgeService, userId, badgeId)
	if not ok then
		-- Service hiccup; fail closed (treat as not owned) but don't crash
		has = false
	end
	badgeCache[userId][badgeId] = has
	return has
end

local function userOwnsGamepass(userId: number, passId: number): boolean
	gamepassCache[userId] = gamepassCache[userId] or {}
	if gamepassCache[userId][passId] ~= nil then
		return gamepassCache[userId][passId]
	end
	local ok, owns = pcall(marketplaceService.UserOwnsGamePassAsync, marketplaceService, userId, passId)
	if not ok then
		owns = false
	end
	gamepassCache[userId][passId] = owns
	return owns
end

-- Flashlight Utilities --
local function cloneFlashlightTool(plr: Player, flashlightTool: Tool)
	if not plr or not flashlightTool then return end

	-- If the player has an existing flashlight in their backpack, destory it.
	local existingFlashlight = plr.Backpack:FindFirstChild(flashlightToolName)
	if existingFlashlight then
		existingFlashlight:Destroy()
	end

	-- Search starter gear for the existing flashlight. Clear it out if present.
	local starterGear = plr:FindFirstChild("StarterGear") or plr:WaitForChild("StarterGear")
	local existingStarterFlashlight = starterGear:FindFirstChild(flashlightToolName)
	if existingStarterFlashlight then
		existingStarterFlashlight:Destroy()
	end

	-- Check if the new flashlight should be equipped or not and delete existing flashlights inside of the player's character.
	local shouldEquip = false
	local character = plr.Character
	if character then
		-- Check if a flashlight exists in the player's character.
		-- If it does, destory it, and equip the new one.
		local characterTool = character:FindFirstChild(flashlightToolName)
		if characterTool then
			characterTool:Destroy()
			shouldEquip = true
		end
	end

	-- Clone the tool to starter gear.
	local starterGearClone = flashlightTool:Clone()
	starterGearClone.Name = flashlightToolName
	starterGearClone.Parent = starterGear

	-- Clone the tool to the player.
	local toolClone = flashlightTool:Clone()
	toolClone.Name = flashlightToolName

	-- Prefer equipping via Backpack (more reliable when Humanoid exists)
	if shouldEquip and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
		toolClone.Parent = plr.Backpack
		local humanoid: Humanoid? = plr.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Attempt equip; if Roblox rejects, at least it's in Backpack.
			pcall(function()
				humanoid:EquipTool(toolClone)
			end)
		end
	else
		toolClone.Parent = plr.Backpack
	end
end

local function playerOwnsFlashlight(plr: Player, flashlightData: flashlightDataType.flashlightData): boolean
	if not plr or not flashlightData then
		return false
	end

	-- Quick check --
	if flashlightData.requirementType == flashlightRequirementTypes.none then
		return true
	end

	-- Get the player's rank in the group and based off of the required type return if they have the flashlight or not.
	local plrRankInGroup = 0
	local ok, rank = pcall(function()
		return plr:GetRankInGroup(groupIDUsed)
	end)
	if ok and typeof(rank) == "number" then
		plrRankInGroup = rank
	end

	-- Give developer all flashlights.
	if plrRankInGroup > 250 then
		return true
	end
	
	-- Handle group flashlight ownership/
	if flashlightData.requiredGroupRanks then
		
		-- If the flashlight requires a specific group rank, then return if the player has one of the required ranks.
		if flashlightData.requirementType == flashlightRequirementTypes.requireSpecificGroupRank then
			return table.find(flashlightData.requiredGroupRanks, plrRankInGroup) ~= nil
		end

		if flashlightData.requirementType == flashlightRequirementTypes.requireGroupRankOrHigher then
			local lowestRankInTable = getLowestValueInTable(flashlightData.requiredGroupRanks)
			return plrRankInGroup >= lowestRankInTable
		end
	end

	-- If there are required badges, see how many the player owns.
	local numBadgesOwned = 0
	if flashlightData.requiredBadges then
		for _, badgeID in ipairs(flashlightData.requiredBadges) do
			if userHasBadge(plr.UserId, badgeID) then
				numBadgesOwned += 1
			end
		end
	end

	-- If the player owns all of the badges and the flashlight requires the user to own all badges, return whether or not this is true.
	if flashlightData.requirementType == flashlightRequirementTypes.requireAllBadges and flashlightData.requiredBadges then
		return numBadgesOwned == #flashlightData.requiredBadges
	end

	-- If the player just has to have one badge, return if that is true.
	if flashlightData.requirementType == flashlightRequirementTypes.requireAnyBadge then
		return numBadgesOwned > 0
	end

	-- If there is a required gamepass, check if the player owns it.
	local numGamepassesOwned = 0
	if flashlightData.requiredGamepasses then
		for _, gamepassID in ipairs(flashlightData.requiredGamepasses) do
			if userOwnsGamepass(plr.UserId, gamepassID) then
				numGamepassesOwned += 1
			end
		end
	end

	-- If the player owns all of the gamepasses and the flashlight requires the user to own all gamepasses, return whether or not this is true.
	if flashlightData.requirementType == flashlightRequirementTypes.requireAllGamepasses and flashlightData.requiredGamepasses then
		return numGamepassesOwned == #flashlightData.requiredGamepasses
	end

	-- If the player just has to have one gamepass, return if that is true.
	if flashlightData.requirementType == flashlightRequirementTypes.requireAnyGamepass then
		return numGamepassesOwned > 0
	end

	-- If the flashlight requires a specific user ID, then return if the player has one of the required user IDs.
	if flashlightData.requirementType == flashlightRequirementTypes.requireUserID and flashlightData.requiredUserIDs then
		return table.find(flashlightData.requiredUserIDs, plr.UserId) ~= nil
	end

	-- If the flashlight requires ALL gamepasses OR ALL badges, return the result (only evaluate sets that exist).
	if flashlightData.requirementType == flashlightRequirementTypes.requireAllGamepassesOrAllBadges then
		local hasAllPasses = false
		local hasAllBadges = false

		if flashlightData.requiredGamepasses and #flashlightData.requiredGamepasses > 0 then
			hasAllPasses = (numGamepassesOwned == #flashlightData.requiredGamepasses)
		end
		if flashlightData.requiredBadges and #flashlightData.requiredBadges > 0 then
			hasAllBadges = (numBadgesOwned == #flashlightData.requiredBadges)
		end

		return hasAllPasses or hasAllBadges
	end

	-- The player does not own the flashlight.
	warn("Flashlight ownership check fell through for", plr, "— verify requirementType and data tables.")
	return false
end

local function equipFlashlight(plr: Player, flashlightDataName: string)
	if not plr or typeof(flashlightDataName) ~= "string" then
		return
	end

	-- Verify that the player isn't on cooldown (atomic dictionary check).
	if equipDebounce[plr.UserId] then
		return
	end

	-- Verify that the player's equipped value exists.
	local plrFlashlightValue = getEquippedFlashlightValue(plr)
	if not plrFlashlightValue or typeof(plrFlashlightValue.Value) ~= "string" then
		return
	end

	-- Verify that the player isn't equipping the same flashlight.
	if plrFlashlightValue.Value == flashlightDataName then
		return
	end

	-- Verify that the flashlight exists.
	local flashlightData = flashlightDataType[flashlightDataName]
	if not flashlightData then
		return
	end

	-- Verify that the player owns the flashlight.
	if not playerOwnsFlashlight(plr, flashlightData) then
		return
	end

	-- The player is now on cooldown.
	equipDebounce[plr.UserId] = true

	-- Clone the flashlight tool.
	cloneFlashlightTool(plr, flashlightData.flashlightTool)

	-- Update the equipped flashlight value.
	plrFlashlightValue.Value = flashlightDataName

	-- Wait a bit, then remove the debounce (guard if player left).
	task.delay(plrDebounceSeconds, function()
		equipDebounce[plr.UserId] = nil
	end)
end

-- Client -> Server Communication --
local THROTTLE_SECONDS = 2.0 -- allow UI refresh but prevent spamming

local function formatFlashlightPayload(plr: Player)
	local equippedFlashlightValue = getEquippedFlashlightValue(plr)
	local equippedName = equippedFlashlightValue and equippedFlashlightValue.Value or nil

	local formattedData = {}

	for dataName, flashlightData in pairs(flashlightDataType) do
		-- Skip non-table entries, if any
		if typeof(flashlightData) ~= "table" then
			continue
		end

		-- See if the player owns the flashlight. If they don't and the flashlight is not visible unless owned, then skip this flashlight.
		local ownsFlashlight = playerOwnsFlashlight(plr, flashlightData)
		if not ownsFlashlight and not flashlightData.showIfUnowned then
			continue
		end

		-- Check if this flashlight is currently equipped.
		local equipped = (equippedName ~= nil and dataName == equippedName) or false

		local formattedClientData = {
			dataName = dataName,
			guiName = flashlightData.name,
			description = flashlightData.description,
			requirementsDescription = flashlightData.requirementsDescription,
			layoutOrder = flashlightData.layoutOrder,

			specialBackgroundColor = flashlightData.specialBackgroundColor,
			brightness = flashlightData.brightness,
			range = flashlightData.range,
			imageId = flashlightData.imageId,

			isCurrentlyEquipped = equipped,
			isOwned = ownsFlashlight
		}

		-- Insert the formatted data into the flashlight.
		table.insert(formattedData, formattedClientData)

		-- If we somehow end up with several hundered flashlights, prevent overlooping.
		task.wait()
	end

	return formattedData
end

local function getFlashlightData(plr: Player)
	if not plr then
		return nil
	end

	local userId = plr.UserId
	local now = os.clock()
	local last = receivedDataOnce[userId]

	-- Throttle requests (not a one-time lockout, so mid-session purchases can refresh).
	if last and (now - last) < THROTTLE_SECONDS then
		return lastFlashlightPayload[userId]
	end

	-- Produce a fresh snapshot
	local payload = formatFlashlightPayload(plr)

	-- Save and timestamp
	lastFlashlightPayload[userId] = payload
	receivedDataOnce[userId] = now

	return payload
end

local function playerRemoving(plr: Player)
	local userId = plr.UserId

	-- Cleanup all dictionaries for this player
	receivedDataOnce[userId] = nil
	lastFlashlightPayload[userId] = nil
	equipDebounce[userId] = nil
	badgeCache[userId] = nil
	gamepassCache[userId] = nil
end

-- Data Loading Function --
local function loadPlayerFlashlight(plr: Player)
	if not plr then return end

	-- Get the player's equipped flashlight value.
	local equippedFlashlight = getEquippedFlashlightValue(plr)
	if not equippedFlashlight or typeof(equippedFlashlight.Value) ~= "string" then
		-- If no value yet, fall back to default
		cloneFlashlightTool(plr, defaultFlashlight.flashlightTool)
		return
	end

	-- Verify that the flashlight exists.
	local equippedFlashlightData = flashlightDataType[equippedFlashlight.Value]
	if not equippedFlashlightData then
		equippedFlashlightData = defaultFlashlight
	end

	-- Verify that the player owns the flashlight.
	local plrOwns = playerOwnsFlashlight(plr, equippedFlashlightData)
	if not plrOwns then
		equippedFlashlightData = defaultFlashlight
	end

	-- Clone the flashlight to the player's starter gear and backpack.
	cloneFlashlightTool(plr, equippedFlashlightData.flashlightTool)
end

-- Events --
dataLoadedEvent.Event:Connect(loadPlayerFlashlight)
players.PlayerRemoving:Connect(playerRemoving)

equipFlashlightEvent.OnServerEvent:Connect(equipFlashlight)
getFlashlightDataFunction.OnServerInvoke = getFlashlightData
