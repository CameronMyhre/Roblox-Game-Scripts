---- Settings ----
local pathfindingService = game:GetService("PathfindingService")
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local debris = game:GetService("Debris")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(1, Enum.EasingStyle.Quad)

---- Modules ----
local modules = serverStorage:WaitForChild("Modules")
local droneModules = modules:WaitForChild("Drones")
local droneEnums = droneModules:WaitForChild("Enums")
local droneStates = require(droneEnums:WaitForChild("DroneActionState"))

local framework = serverStorage:WaitForChild("Framework")
local frameworkModules = framework:WaitForChild("Modules")
local healthManager = require(frameworkModules:WaitForChild("Health Manager"))

---- Objects ----
local drones = workspace:WaitForChild("Drones")

local drone = script.Parent
local humanoidRootPart = drone:WaitForChild("HumanoidRootPart")
local rotationAlign = humanoidRootPart:WaitForChild("AlignOrientation")

local eye = drone:WaitForChild("Emitter")
local emissionPoint = eye:WaitForChild("Emit")
local glowParticle = emissionPoint:WaitForChild("Glow")
local nuzzleFlashParticle = emissionPoint:WaitForChild("Nuzzleflash")
local smokeParticle = emissionPoint:WaitForChild("Smoke")
local texturedSmokeParticle = emissionPoint:WaitForChild("TexturedSmoke")

local humanoid = drone:WaitForChild("Humanoid")

local doorFolder = workspace:WaitForChild("Doors")

local invisiblePartsFolder = workspace:WaitForChild("Invisible Parts")
local pathfindingFolder = invisiblePartsFolder:WaitForChild("Pathfinding")
local waypointFolder = pathfindingFolder:WaitForChild("Waypoints-Factory")
local availableWaypoints = waypointFolder:GetChildren()

---- SFX ----
local shotSFX = emissionPoint:WaitForChild("ShotSound")

---- Settings ----
-- General Settings --
local turningResponsiveness = 10

-- Attack Settings --
local startAttackRange = 25
local maxAttackRange = 40
local attackRequiresLineOfSight = true

local attackDamage = 2.5
local attackRechargeTime = .5
local maxBulletSpreadAngleRadians = math.rad(1)

local attackTurningResponsiveness = 30

-- Target Settings --
local maxDetectionRange = 100
local maxSightDistance = 40
local hearingDistancePerWalkspeed = 1.5
local movementMagnitudeThreshold = 0.1

local targetScanTime = .15 -- Seconds in between scans.
local canSeeTargetScanTime = .1

local seeingRaycastParams = RaycastParams.new()
seeingRaycastParams.FilterDescendantsInstances = {drones, invisiblePartsFolder}
seeingRaycastParams.FilterType = Enum.RaycastFilterType.Exclude -- exclude self so we don’t raycast-hit the drone
seeingRaycastParams.IgnoreWater = true
seeingRaycastParams.RespectCanCollide = true

-- Chase Settings --
local chaseSpeed = 20
local memoryTime = 10 -- #seconds before forgetting a target after line of sight is broken.
local chaseRepathDelay = 0.35 -- #seconds before re-pathfinding to target (slightly higher to reduce thrash)
local minChaseRepathDistance = 5 -- #studs the target must move from our last chase goal before we repath
local minChaseNoSeeDistance = 1

-- Wander Settings --
local wanderSpeed = 18

-- Searching --
local totalSearchRotationRadians = 4 * math.pi
local searchRadiansPerSecond = math.rad(180)

-- Pathfinding (base settings reused for each compute) --
local pathSettings = {
	AgentRadius = 2,
	AgentHeight = 1,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 2,
	Costs = {
		Plastic = 1,
		SmoothPlastic = 1,
		OpenDoor = 2,
		Avoid = math.huge,
		SafeZone = math.huge,
	}
}

-- Pathfollowing --
local openDoorLabel = "OpenDoor"
local overlapParams = OverlapParams.new()
overlapParams.FilterDescendantsInstances = {doorFolder}
overlapParams.FilterType = Enum.RaycastFilterType.Include
local doorSearchRadiusStuds = 5
local doorPointOffset = Vector3.new(0, 4, 0)

local pointReachedThresholdStuds = 1.5

-- *** New tuning knobs to prevent spin on tiny paths / same-point targets
local minNewTargetDistanceStuds = 12         -- don’t select a new target this close to the drone
local minPathLengthForSearch = 8              -- only enter `searching` if the path was at least this long

-- *** Movement command throttling to prevent MoveTo spam/jitter
local moveToCooldown = 0.1     -- seconds between MoveTo commands to the same point
local moveToSamePointEpsilon = 0.1 -- don’t resend MoveTo if the target changed by less than this

-- *** Waypoint filtering to prevent backward step on repath
local firstWaypointMinAdvance = 1.25  -- if the first node is closer than this, skip it
local firstWaypointBehindDot = -0.05  -- skip if the first node is behind us (dot in XZ < this)

---- Flags ----
-- General --
local stateChanging = false

-- Pathfinding --
local stalled = false
local computingPath = false
local hasPath = false
local repathQueued = false

-- Chasing --
local canSeeTarget = false

---- Storage ----
-- General --
local currentState: droneStates.DroneState = droneStates.wandering

-- Attack --
local attackTimer = 0

-- Chasing --
local timeSinceLastChaseRepath = 0
local timeSinceTargetSpotted = 0
local target = nil
local lastKnownTargetPosition: Vector3? = nil -- last LOS position to reduce thrash
local lastChaseGoal: Vector3? = nil          -- what we last computed a path to

-- Targets --
local timeSinceTargetScan = 0
local timeSinceCanSeeScan = 0

-- Searching --
local totalRadiansTurned = 0

-- Pathfinding --
local currentWaypointNum: number = -1
local currentWaypointObj: PathWaypoint? = nil

local computedWaypoints = {}
local activePath: Path = nil
local pathBlockedConnection: RBXScriptConnection? = nil
local targetPoint: BasePart? = nil

-- *** Track the length of the currently adopted path
local currentPathDistanceStuds: number = 0

-- *** MoveTo state
local lastMoveToTime: number = 0
local lastMoveToPosition: Vector3? = nil
local moveFinishedConn: RBXScriptConnection? = nil

-- *** Simple “stuck” detector to kick a repath if bumped by players
local stuckTime: number = 0
local stuckSpeedThreshold = 0.5 -- speed below which we consider the drone “stuck”
local stuckDurationToRepath = 1.0 -- seconds stuck before we repath once

-- *** Door-guard: while true, MoveToFinished will NOT auto-advance past an OpenDoor node
local suppressMoveFinishedAdvance = false

---- One-time init hardening ----
-- Keep server authority so touching players don’t snatch network ownership (reduces jitter).
pcall(function()
	humanoidRootPart:SetNetworkOwner(nil)
end)

---- Functions ----
-- Overarching Utilities --
local function playSound(sound: Sound)
	local soundClone = sound:Clone()
	soundClone.Parent = sound.Parent
	soundClone:Play()
	debris:AddItem(soundClone, sound.TimeLength)
end

-- Drone State --
local function updateState(newState: droneStates.DroneState)

	-- Return if we are trying to set the state to the value it already is.
	if newState == currentState then
		return
	end

	stateChanging = true

	-- Clean up state specific value when exiting the state.
	if currentState == droneStates.wandering then

		-- The drone no longer has a path.
		totalRadiansTurned = 0
		hasPath = false
	elseif currentState == droneStates.searching then

		-- Clear out the rotations that the drone made and unanchor the drone so it can move again.
		totalRadiansTurned = 0
		humanoidRootPart.Anchored = false

		-- Revert network ownership, since anchoring the part resets it.
		humanoidRootPart:SetNetworkOwner(nil)
	elseif currentState == droneStates.chasing then
		
		-- Clear out chase pathing and target info.
		-- NOTE: do NOT clear the target when transitioning into ATTACKING, or LOS checks will receive nil.
		if newState ~= droneStates.attacking then
			target = nil
			canSeeTarget = false
		end

		timeSinceTargetSpotted = 0
		timeSinceLastChaseRepath = 0

		lastKnownTargetPosition = nil
		lastChaseGoal = nil
		hasPath = false

		-- Only disable facing helpers if we are NOT going into attacking.
		if newState ~= droneStates.attacking then
			rotationAlign.Enabled = false
			humanoid.AutoRotate = true
		end
	elseif currentState == droneStates.attacking then

		-- Revert changes settings.
		rotationAlign.Responsiveness = turningResponsiveness
		
		-- Revert all time sensitive variables.
		timeSinceTargetSpotted = 0
		timeSinceLastChaseRepath = 0
	
		attackTimer = 0
		hasPath = false
	end

	-- Update the drone state.
	currentState = newState
	stateChanging = false
end

-- Attacking --
local function shootTarget()
	
	local targetPart = targetPoint
	
	-- Attempt to find the target's head.
	local head = target:FindFirstChild("Head")
	if head then
		targetPart = head
	end
	
	-- Emit particles.
	glowParticle:Emit(2)
	nuzzleFlashParticle:Emit(2)
	texturedSmokeParticle:Emit(5)
	smokeParticle:Emit(5)

	-- Play the sound effect.
	playSound(shotSFX)
	
	-- Fire a raycast towards the player --
	-- Calculate the angle the bullet will be fired at.
	local x, y, z = humanoidRootPart.CFrame:ToEulerAnglesXYZ()
	local shotAngle = CFrame.Angles(x + math.random(-maxBulletSpreadAngleRadians, maxBulletSpreadAngleRadians), y + math.random(-maxBulletSpreadAngleRadians, maxBulletSpreadAngleRadians), z + math.random(-maxBulletSpreadAngleRadians, maxBulletSpreadAngleRadians))
	
	-- Calculate the direction of the raycast.
	local adjustedDronePose = CFrame.new(humanoidRootPart.CFrame.X, targetPart.CFrame.Y, humanoidRootPart.CFrame.Z) * shotAngle
	local direction = adjustedDronePose.LookVector.Unit
	
	-- Fire the raycast and damage the player if it hits them.
	local raycastResult = workspace:Raycast(eye.CFrame.Position, direction * maxAttackRange, seeingRaycastParams)
	if not raycastResult then
		return
	end
	
	-- Damage the player if they get hit.
	if raycastResult.Instance:IsDescendantOf(target) then
		healthManager:adjustHealth(players:GetPlayerFromCharacter(target), -attackDamage, false, false)
	end
end

-- Target Finding --
local function canDroneSeeTarget(targetChar, hrp: Part?): boolean

	-- Verify that the target isn't nil.
	if not targetChar then
		return false
	end

	-- Get the target's humanoid root part if it wasn't provided.
	local targetHumanoidRootPart = hrp
	if not hrp then
		targetHumanoidRootPart = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetHumanoidRootPart then
			return false
		end
	end

	-- Calculate the look vector from the drone to the target.
	local origin = humanoidRootPart.Position
	local direction = (targetHumanoidRootPart.Position - origin)
	local distance = direction.Magnitude
	if distance > maxSightDistance then
		return false
	end
	direction = direction.Unit * maxSightDistance

	-- Fire off the raycast.
	local raycastResult = workspace:Raycast(origin, direction, seeingRaycastParams)
	if not raycastResult or not raycastResult.Instance then
		return false -- No player detected.
	end

	-- Return true if the target can be seen.
	if raycastResult.Instance:IsDescendantOf(targetChar) then
		return true
	end

	-- No target can be seen.
	return false
end

local function findTarget()

	-- Closest Target --
	local foundTarget
	local targetRootPart
	local closestTargetDistance = 999
	local canSeePossibleTarget = false

	for _, player in ipairs(players:GetChildren()) do

		-- Get the character.
		local character = player.Character
		if not character then
			continue
		end

		-- Attempt to get the humanoid root part and humanoid for checks.
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local plrHumanoid: Humanoid = character:FindFirstChildOfClass("Humanoid")
		if not (hrp and plrHumanoid) then
			continue
		end

		-- Verify that the potential target is alive.
		if plrHumanoid.Health <= 0 then
			continue
		end

		-- Get the distance to the player and check if it is out of range.
		local distanceToPlr = humanoidRootPart.CFrame:ToObjectSpace(hrp.CFrame).Position.Magnitude
		if distanceToPlr > maxDetectionRange then
			continue
		end

		-- Vision Detection --
		local canSee = false
		if distanceToPlr <= maxSightDistance then
			canSee = canDroneSeeTarget(character, hrp)
		end

		-- If the target can be seen, then check if it is closer than the current target.
		if canSee then
			-- If the player is closer than the current target, or the player can be seen and the current target cannot, overrite the current target.
			if distanceToPlr < closestTargetDistance or not canSeePossibleTarget then
				foundTarget = character
				closestTargetDistance = distanceToPlr
				targetRootPart = hrp
				canSeePossibleTarget = canSee
			end
			continue
		end

		-- Always prioritize targets that can be seen.
		if canSeePossibleTarget and not canSee then
			continue
		end

		-- Hearing Detection --
		local noiseRange = hearingDistancePerWalkspeed * plrHumanoid.WalkSpeed
		if hrp.Velocity.Magnitude <= 12 then
			noiseRange = 0
		end
		if noiseRange >= distanceToPlr and plrHumanoid.MoveDirection.Magnitude > movementMagnitudeThreshold then
			-- If the player is closer than the current target, overwrite the current target.
			if distanceToPlr < closestTargetDistance then
				foundTarget = character
				closestTargetDistance = distanceToPlr
				targetRootPart = hrp
			end
		end
	end

	-- Return the found target.
	return foundTarget, targetRootPart, canSeePossibleTarget
end

local function attemptToUpdateTarget(requireSight: boolean)

	-- Try to find a possible target. If one cannot be found, then return.
	local possibleTarget, targetRootPart, canSeePossibleTarget = findTarget()
	if possibleTarget and (not requireSight or (requireSight and canSeePossibleTarget)) then

		-- Chase the player only if they are not attacking.
		if currentState ~= droneStates.attacking then
			updateState(droneStates.chasing)
		end

		-- If the target is not the current target, then update the target.
		if possibleTarget ~= target then
			target = possibleTarget
			canSeeTarget = canSeePossibleTarget
			targetPoint = targetRootPart
		end

		-- Update the last known position of the target.
		if canSeePossibleTarget and targetRootPart then
			lastKnownTargetPosition = targetRootPart.Position -- remember where they were seen
		end
	end
end

-- Utility
local function planarDistance(a: Vector3, b: Vector3): number
	-- Compare in XZ plane so height differences don’t confuse “close enough”
	local da = Vector3.new(a.X, 0, a.Z)
	local db = Vector3.new(b.X, 0, b.Z)
	return (da - db).Magnitude
end

-- *** dot on XZ plane (used to see if a point is behind us)
local function planarDotTo(point: Vector3): number
	local forward = Vector3.new(humanoidRootPart.CFrame.LookVector.X, 0, humanoidRootPart.CFrame.LookVector.Z)
	local toPoint = Vector3.new(point.X - humanoidRootPart.Position.X, 0, point.Z - humanoidRootPart.Position.Z)
	if toPoint.Magnitude < 1e-3 then
		return 1 -- treat as forward if essentially same point
	end
	return forward.Unit:Dot(toPoint.Unit)
end

-- *** Compute total path length (3D is fine here)
local function computePathLength(waypoints: {PathWaypoint}): number
	local dist = 0
	for i = 2, #waypoints do
		dist += (waypoints[i].Position - waypoints[i-1].Position).Magnitude
	end
	return dist
end

local function clearCurrentPath()
	computedWaypoints = {}
	currentWaypointObj = nil
	currentWaypointNum = -1
	hasPath = false
	currentPathDistanceStuds = 0
	if pathBlockedConnection then
		pathBlockedConnection:Disconnect()
		pathBlockedConnection = nil
	end
	activePath = nil
	-- When path is gone, no door is being processed.
	suppressMoveFinishedAdvance = false
end

--[[ Select a sensible first waypoint so we don’t step backward on repath.
We skip the first node if it’s too close to our current position OR behind our facing. ]]
local function chooseInitialWaypointIndex(waypoints: {PathWaypoint}): number
	if #waypoints < 2 then
		return 1
	end
	local first = waypoints[1]
	-- If the first node is an OpenDoor, don’t skip it (links need to be honored).
	if first.Label == openDoorLabel then
		return 1
	end
	local d = planarDistance(first.Position, humanoidRootPart.Position)
	local dot = planarDotTo(first.Position)
	if d <= firstWaypointMinAdvance or dot <= firstWaypointBehindDot then
		return 2
	end
	return 1
end

--[[
Attempts to travel to the next waypoint. If there is no next waypoint:
- If the path was “real” (>= minPathLengthForSearch), go to searching (spin).
- Otherwise, just clear and let wandering pick a better target (prevents spin on tiny 2-node paths).
]]
local function updateWaypointTarget()
	currentWaypointNum += 1
	if currentWaypointNum <= #computedWaypoints then
		currentWaypointObj = computedWaypoints[currentWaypointNum]
		-- *** If we just switched TO a door node, suppress MoveToFinished from advancing past it.
		if currentWaypointObj and currentWaypointObj.Label == openDoorLabel then
			suppressMoveFinishedAdvance = true
		else
			suppressMoveFinishedAdvance = false
		end
	else
		local shouldSearch = currentPathDistanceStuds >= minPathLengthForSearch and currentState ~= droneStates.chasing and currentState ~= droneStates.attacking -- TODO: RECENTLY ADDED
		clearCurrentPath()
		if shouldSearch then
			updateState(droneStates.searching) -- wander -> searching
		end
	end
end

-- When MoveTo finishes (success or failure), advance waypoint if we are following a path.
local function onMoveToFinished(reached: boolean)
	-- Only advance if we’re actually following path waypoints right now.
	if currentWaypointObj then
		-- *** Do NOT auto-advance past door waypoints; door logic must run first.
		if suppressMoveFinishedAdvance or (currentWaypointObj.Label == openDoorLabel) then
			return
		end
		-- If we failed to reach (blocked), let the “stuck” logic or Blocked event trigger a repath.
		if reached then
			updateWaypointTarget()
		end
	end
end

-- Utility: safely adopt a newly computed path only if it's good.
local function adoptPath(newPath: Path, newWaypoints: {PathWaypoint})
	if pathBlockedConnection then
		pathBlockedConnection:Disconnect()
		pathBlockedConnection = nil
	end
	activePath = newPath
	computedWaypoints = newWaypoints

	-- *** pick a forward/meaningful starting node to avoid backward step
	local startIndex = chooseInitialWaypointIndex(newWaypoints)
	currentWaypointNum = startIndex
	currentWaypointObj = computedWaypoints[currentWaypointNum]
	hasPath = true

	-- *** Set/clear the door guard based on the first node of this path
	if currentWaypointObj and currentWaypointObj.Label == openDoorLabel then
		suppressMoveFinishedAdvance = true
	else
		suppressMoveFinishedAdvance = false
	end

	-- *** Store path length so we can decide whether to enter `searching` at the end
	currentPathDistanceStuds = computePathLength(newWaypoints)

	pathBlockedConnection = activePath.Blocked:Connect(function(blockedIndex: number)
		if blockedIndex and blockedIndex < currentWaypointNum then
			return
		end
		repathQueued = true
	end)

	-- Ensure MoveToFinished handler exists once.
	if not moveFinishedConn then
		moveFinishedConn = humanoid.MoveToFinished:Connect(onMoveToFinished)
	end

	-- Reset MoveTo throttling for the new path.
	lastMoveToTime = 0
	lastMoveToPosition = nil
end

local function findClosestDoor()
	local closestDoor
	local closestDoorDistance = math.huge
	local seenDoors = {}

	local nearbyDoorParts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, doorSearchRadiusStuds, overlapParams)
	for _, part in ipairs(nearbyDoorParts) do
		local possibleDoor = part.Parent
		if not possibleDoor or possibleDoor.Parent ~= doorFolder then
			continue
		end
		if table.find(seenDoors, possibleDoor) then
			continue
		end
		table.insert(seenDoors, possibleDoor)

		local pathfindingPart = possibleDoor:FindFirstChild("PathfindingConnectionPoint")
		if not pathfindingPart then
			continue
		end

		local distanceToDoor = (part.Position - humanoidRootPart.Position).Magnitude
		if distanceToDoor < closestDoorDistance then
			closestDoor = possibleDoor
			closestDoorDistance = distanceToDoor
		end
	end

	return closestDoor
end

local function openDoorPathfindingLink()
	if stalled then return end
	stalled = true

	local closestDoor = findClosestDoor()
	if not closestDoor then
		stalled = false
		clearCurrentPath()
		repathQueued = true
		return
	end

	local openDoorFunction = closestDoor:FindFirstChild("OpenDoorFunction")
	local pathfindingPart = closestDoor:FindFirstChild("PathfindingConnectionPoint")
	if not openDoorFunction or not pathfindingPart then
		stalled = false
		clearCurrentPath()
		repathQueued = true
		return
	end

	local frontAttachment = pathfindingPart:FindFirstChild("FrontAttachment") or pathfindingPart:FindFirstChild("FrontAttachment")
	local backAttachment  = pathfindingPart:FindFirstChild("BackAttachment")  or pathfindingPart:FindFirstChild("BackAttachment")
	if not frontAttachment or not backAttachment then
		stalled = false
		clearCurrentPath()
		repathQueued = true
		return
	end

	-- Ask the door if it was already open
	local alreadyOpen, openTweenTime = false, 0
	local ok, a, b = pcall(function()
		return openDoorFunction:Invoke()
	end)
	if ok then
		alreadyOpen = a == true
		openTweenTime = typeof(b) == "number" and b or 0
	end

	if alreadyOpen then
		-- Door is open: skip special tweening and waiting. Just continue along the path.
		-- *** We’re done with the door, normal MoveToFinished advance can resume.
		updateWaypointTarget()
		suppressMoveFinishedAdvance = false
		stalled = false
		return
	end

	-- Door is opening now: wait for the door’s own tween so we don’t clip it,
	-- but DO NOT tween the drone, just advance after it’s open.
	if openTweenTime > 0 then
		task.wait(openTweenTime)
	end

	updateWaypointTarget()
	-- *** Door handled; re-enable normal MoveToFinished behavior (unless next is another door).
	if currentWaypointObj and currentWaypointObj.Label ~= openDoorLabel then
		suppressMoveFinishedAdvance = false
	end
	stalled = false
end

-- Issue a MoveTo with throttling so we don’t spam and reset pathfinding every frame.
local function issueMoveTo(position: Vector3)
	local now = os.clock()
	if lastMoveToPosition and (position - lastMoveToPosition).Magnitude < moveToSamePointEpsilon and (now - lastMoveToTime) < moveToCooldown then
		return -- recent identical MoveTo; ignore
	end
	lastMoveToPosition = position
	lastMoveToTime = now
	humanoid:MoveTo(position)
end

local function moveToPoint(position: Vector3)
	-- *** If the current waypoint ended up behind us (rare), advance once to avoid reversing.
	if currentWaypointObj and currentWaypointNum == 1 then
		local dot = planarDotTo(currentWaypointObj.Position)
		if dot <= firstWaypointBehindDot then
			updateWaypointTarget()
			if currentWaypointObj then
				position = currentWaypointObj.Position
			end
		end
	end

	-- "Reached" is now handled via MoveToFinished; we still send MoveTo but throttled.
	issueMoveTo(position)

	-- Fallback early-advance if we are already very close in XZ plane (covers cases where MoveToFinished may not fire due to tiny steps).
	local flatTarget = Vector3.new(position.X, humanoidRootPart.Position.Y, position.Z)
	local distanceToPoint = (humanoidRootPart.Position - flatTarget).Magnitude
	if distanceToPoint <= pointReachedThresholdStuds * 0.6 then
		-- *** Don’t chain-skip: if the *next* node is a door, let the next tick handle it.
		updateWaypointTarget()
	end
end

local function followPath()
	if computingPath or stalled then
		return
	end
	if not currentWaypointObj then
		return
	end

	if currentWaypointObj.Label == openDoorLabel then
		openDoorPathfindingLink()
	else
		moveToPoint(currentWaypointObj.Position)
	end
end

local function generatePath(partToPathfindTo: BasePart)
	if computingPath then
		repathQueued = true
		targetPoint = partToPathfindTo
		return
	end

	computingPath = true
	targetPoint = partToPathfindTo

	local newPath = pathfindingService:CreatePath(pathSettings)

	local ok = pcall(function()
		newPath:ComputeAsync(humanoidRootPart.Position, partToPathfindTo.Position)
	end)

	if not ok then
		computingPath = false
		repathQueued = true
		return
	end

	if newPath.Status ~= Enum.PathStatus.Success then
		computingPath = false
		clearCurrentPath()
		return
	end

	local newWaypoints = newPath:GetWaypoints()
	if #newWaypoints < 2 and currentState ~= droneStates.chasing then
		computingPath = false
		clearCurrentPath()
		return
	end

	-- *** Reject paths whose end is “too close” to current position; it’ll cause spin.
	local endPos = newWaypoints[#newWaypoints].Position
	if planarDistance(endPos, humanoidRootPart.Position) < minNewTargetDistanceStuds and currentState ~= droneStates.chasing then -- Ignore during chases to allow for minor adjustments to aim.
		computingPath = false
		clearCurrentPath()
		return
	end

	adoptPath(newPath, newWaypoints)
	computingPath = false
end

-- *** Choose a target waypoint that meaningfully moves us somewhere new
local function chooseNextTargetWaypoint()
	local candidates = table.clone(availableWaypoints)

	-- If possible, avoid reusing the previous target
	if targetPoint and #candidates > 1 then
		local idx = table.find(candidates, targetPoint)
		if idx then table.remove(candidates, idx) end
	end

	-- Filter out candidates that are too close to the current position (planar)
	local filtered = {}
	for _, wp in ipairs(candidates) do
		if planarDistance(wp.Position, humanoidRootPart.Position) >= minNewTargetDistanceStuds then
			table.insert(filtered, wp)
		end
	end

	if #filtered > 0 then
		return filtered[math.random(1, #filtered)]
	end

	-- Fallback: if everything is too close, pick the farthest overall (so we don’t pick the same spot again)
	table.sort(candidates, function(a, b)
		return planarDistance(a.Position, humanoidRootPart.Position) > planarDistance(b.Position, humanoidRootPart.Position)
	end)
	return candidates[1]
end

-- State Functions --
local function wander()

	-- Configure the state of the drone.
	rotationAlign.Enabled = false
	humanoid.WalkSpeed = wanderSpeed

	if not hasPath then
		-- Handle degenerate case: zero waypoints
		if #availableWaypoints == 0 then
			return
		end

		-- Single-waypoint safety: if we’re already near it, don’t flip to searching forever.
		if #availableWaypoints == 1 then
			local only = availableWaypoints[1]
			if planarDistance(only.Position, humanoidRootPart.Position) < minNewTargetDistanceStuds then
				-- Idle here; nothing meaningful to path to.
				return
			end
		end

		targetPoint = chooseNextTargetWaypoint()
		if targetPoint then
			generatePath(targetPoint)
		end
	end

	if computingPath then
		return
	end
	followPath()
end

local function search(deltaTime: number)

	-- Configure the state of the drone.
	rotationAlign.Enabled = false
	humanoidRootPart.Anchored = true

	local rotationAmount = searchRadiansPerSecond * deltaTime
	totalRadiansTurned += rotationAmount
	humanoidRootPart.CFrame *= CFrame.Angles(0, rotationAmount, 0)

	if totalRadiansTurned >= totalSearchRotationRadians then
		updateState(droneStates.wandering) -- searching -> wandering
	end
end

local function chaseTarget(deltaTime: number)

	-- Update the walkspeed to be faster during chases.
	if humanoid.WalkSpeed < chaseSpeed then
		humanoid.WalkSpeed = chaseSpeed
	end
	rotationAlign.Enabled = true
	humanoid.AutoRotate = false

	-- Handle the player clipping out of the map.
	if not targetPoint then
		updateState(droneStates.wandering) -- Return to wandering if the humanoid root part is nil.
		return
	end

	-- Debug print was here; muted to avoid log spam jitter.
	canSeeTarget = canDroneSeeTarget(target)

	-- Track LOS and last known position to reduce thrashing.
	if target and targetPoint then
		if canSeeTarget then
			lastKnownTargetPosition = targetPoint.Position
		end
	end

	-- Repath only when needed: enough time elapsed AND target moved enough from our last goal.
	timeSinceLastChaseRepath += deltaTime
	if targetPoint then
		if (not lastChaseGoal)
			or (lastChaseGoal - targetPoint.Position).Magnitude >= minChaseRepathDistance and (timeSinceLastChaseRepath >= chaseRepathDelay)
			or (timeSinceLastChaseRepath >= chaseRepathDelay and canSeeTarget)
			or (lastChaseGoal - targetPoint.Position).Magnitude >= minChaseNoSeeDistance and not canSeeTarget and (timeSinceLastChaseRepath >= chaseRepathDelay) then
			repathQueued = true
		end
	end

	-- Kick a repath if we’ve been bumped and stuck.
	local planarSpeed = Vector3.new(humanoidRootPart.Velocity.X, 0, humanoidRootPart.Velocity.Z).Magnitude
	if planarSpeed < stuckSpeedThreshold and hasPath then
		stuckTime += deltaTime
		if stuckTime >= stuckDurationToRepath then
			repathQueued = true
			stuckTime = 0
		end
	else
		stuckTime = 0
	end

	-- Compute a path if we don’t have one.
	if not hasPath and targetPoint then
		generatePath(targetPoint)
	end

	-- If the path is being completed then return.
	if computingPath then
		return
	end

	-- Compute the distance to the target. This will be used to determine if the target is close enough to attack.
	local distanceToTarget = humanoidRootPart.CFrame:ToObjectSpace(targetPoint.CFrame).Position.Magnitude
	if distanceToTarget <= startAttackRange and (canSeeTarget and attackRequiresLineOfSight or not attackRequiresLineOfSight) then
		updateState(droneStates.attacking) -- Chase -> Attacking
		return
	end

	-- Follow the path.
	followPath()
end

local function attackTarget(deltaTime: number)

	-- Handle the player clipping out of the map.
	if not targetPoint then
		updateState(droneStates.wandering) -- Return to wandering if the humanoid root part is nil.
		return
	end	

	-- Compute the distance to the target. This will be used to determine if chase must be entered again.
	local distanceToTarget = humanoidRootPart.CFrame:ToObjectSpace(targetPoint.CFrame).Position.Magnitude
	if distanceToTarget > maxAttackRange then
		updateState(droneStates.chasing) -- Attacking -> Chasing
		return
	end

	-- If the attack requires sight and the target cannot be seen, resume chasing.
	if attackRequiresLineOfSight and not canSeeTarget then
		updateState(droneStates.chasing) -- Attacking -> Chasing
		return
	end

	-- Enable auto rotation.
	rotationAlign.Enabled = true
	humanoid.AutoRotate = false
	rotationAlign.Responsiveness = attackTurningResponsiveness

	-- Increment the time since the last attack.
	attackTimer += deltaTime

	if attackTimer >= attackRechargeTime then

		-- Reset the timer.
		attackTimer = 0

		-- Fire a projectile.
		shootTarget()
	end
end

-- Align Orientation --
local function yawLookAt(fromPos: Vector3, toPos: Vector3, up: Vector3)
	-- Project the aim vector onto the XZ plane to kill pitch
	local v = toPos - fromPos
	v = Vector3.new(v.X, 0, v.Z)
	if v.Magnitude < 1e-4 then
		return rotationAlign.CFrame -- keep whatever we had
	end
	-- Only the rotation portion is needed for AlignOrientation.CFrame
	return CFrame.lookAt(fromPos, fromPos + v, up).Rotation
end

-- Event Functions --
local function periodic(deltaTime: number)

	if stateChanging then
		return
	end

	-- Process repaths during wandering/chasing only when queued (fix operator precedence).
	if (currentState == droneStates.wandering or currentState == droneStates.chasing) and repathQueued and not computingPath and targetPoint then
		repathQueued = false
		timeSinceLastChaseRepath = 0

		-- For chasing, remember what we’re repathing to so we don’t thrash until it really moves again.
		if currentState == droneStates.chasing and targetPoint then
			lastChaseGoal = targetPoint.Position
		end

		generatePath(targetPoint)
	end

	-- Update timers.
	timeSinceCanSeeScan += deltaTime
	timeSinceTargetScan += deltaTime
	
	-- Try to find a target if one currently isn't set.
	-- If a target is set, see if they can still be seen.
	if not target then
		
		-- If enough time has passed, search for a target.
		if timeSinceTargetScan > targetScanTime then
			timeSinceTargetScan = 0
			attemptToUpdateTarget(false)
		end
	else
		
		-- If enough time has passed, see if the drone can see the target again.
		if timeSinceCanSeeScan > canSeeTargetScanTime then
			timeSinceCanSeeScan = 0
			canSeeTarget = canDroneSeeTarget(target)
		end
	end

	-- Handle loosing the target.
	if target then

		-- Handle loosing track of the target.
		if canSeeTarget then
			timeSinceTargetSpotted = 0
		else

			-- Increment the time without a target. Give up chasing them if the drone's memory time has expired.
			timeSinceTargetSpotted += deltaTime
			if timeSinceTargetSpotted > memoryTime then
				updateState(droneStates.searching)  -- chasing -> searching
				return
			end

			-- Allow the current target to be overridden if we can find a new once that can be seen.
			attemptToUpdateTarget(true)
		end

		-- Update the orientation on the align rotation.
		rotationAlign.CFrame = yawLookAt(humanoidRootPart.CFrame.Position, targetPoint.CFrame.Position, humanoidRootPart.CFrame.UpVector)
	end

	if currentState == droneStates.wandering then
		wander()
		return
	end

	if currentState == droneStates.searching then
		search(deltaTime)
		return
	end

	if currentState == droneStates.chasing then
		chaseTarget(deltaTime)
		return
	end

	if currentState == droneStates.attacking then
		attackTarget(deltaTime)
		return
	end
end

---- Events ----
runService.Heartbeat:Connect(periodic)