-- Services --
local players = game:GetService("Players")
local collectionService = game:GetService("CollectionService")
local debris = game:GetService("Debris")
local serverStorage = game:GetService("ServerStorage")

local tweenService = game:GetService("TweenService")
local barrelTween = TweenInfo.new(.5, Enum.EasingStyle.Quad)
local burningTween = TweenInfo.new(3, Enum.EasingStyle.Quad)

-- Bindable Events --
local framework = serverStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local effectEvents = bindableEvents:WaitForChild("Effect System")
local giveEffectEvent = effectEvents:WaitForChild("GiveEffectEvent")

-- Modules --
local modules = framework:WaitForChild("Modules")
local healthManager = require(modules:WaitForChild("Health Manager"))
local effects = require(modules:WaitForChild("Effects"))

local regularBindableEvents = serverStorage:WaitForChild("Bindable Events")
local spawnNaturalHazardForPlayerEvent = regularBindableEvents:WaitForChild("SpawnNaturalHazardForPlayerEvent")
local spawnNaturalHazardEvent = regularBindableEvents:WaitForChild("SpawnNaturalHazardEvent")

-- Objects --
local invisibleParts = workspace:WaitForChild("Invisible Parts")
local electricalZones = invisibleParts:WaitForChild("Electrical Hazards")

-- VFX --
local oilExplosionSFX = script:WaitForChild("Explosion Sound")

local fireEffects = script:WaitForChild("Burning")
local fireParticles = fireEffects:WaitForChild("Fire")
local initialBurnSFX = fireEffects:WaitForChild("Burned")
local burningSFX = fireEffects:WaitForChild("Fire burning")

local electricalEffects = script:WaitForChild("Electrical")
local FailureSFX = electricalEffects:WaitForChild("Failure")
local zapSFX = electricalEffects:WaitForChild("Zap")
local electricalExplosion = electricalEffects:WaitForChild("electric_explosion")

local lightPointElectrical = electricalEffects:WaitForChild("LightPoint")
local boltParticles = electricalEffects:WaitForChild("Bolts")
local boltParticles2 = electricalEffects:WaitForChild("Bolts2")
local cloudParticlesElectrical = electricalEffects:WaitForChild("Cloud")

local gasEffects = script:WaitForChild("Gas")
local gasLeakSFX = gasEffects:WaitForChild("gas leak")
local gasParticle = gasEffects:WaitForChild("Gas")

local explosionParticles = script:WaitForChild("Explosion")
-- Settings --
local defaultRange = 60
local defaultCooldown = 15

local overlapParams = OverlapParams.new()
overlapParams.CollisionGroup = "E-Hazard-Only-Collision"
overlapParams.RespectCanCollide = false

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "NoDecorations"
local activeTag = "eHazard-IsActive"

-- Explosion Settings --
local explosionOverlapParams = OverlapParams.new()
explosionOverlapParams.MaxParts = 1000

local maxExplosionDamage = 35
local explosionRadius = 20
local burnRadius = 10

local burnDuration = 2.5 -- Seconds

-- Electrical Settings --
local zapDamage = 10
local electricalExplodeTime = 10 -- Seconds
local maxElectricalExplosionDamage = 20
local electricalExplosionRadius = 15

local electricalHitTag = "Zapped"
local electricalTagRemovalTime = 0.5

-- Gas Settings --
local gasHitDamage = 5
local bleedEffectDuration = 5 -- Seconds
local gasHitTag = "GasHit"
local gasTagRemovalTime = 0.5
local gasDuration = 2

---- Functions ----
-- Utility --
local function extractCharacters(possibleCharacterParts: {Instance}): {}
	
	-- If there are no parts to search through, quick return an empty array.
	if #possibleCharacterParts == 0 then
		return {}
	end
	
	local foundCharacters = {}
	for _, instance in ipairs(possibleCharacterParts) do
		
		-- If the instance is not a character, then continue.
		local possibleCharacter = instance.Parent
		if not players:GetPlayerFromCharacter(possibleCharacter) then
			continue
		end
		
		-- If the character has already been added to the list of touched parts, then continue.
		if table.find(foundCharacters, possibleCharacter) then
			continue
		end
		
		-- Add the character to the list of seen characters.
		table.insert(foundCharacters, possibleCharacter)
	end
	
	-- Return the list of found characters.
	return foundCharacters
end

local function removeParticles(particleEmitter: ParticleEmitter)
	
	-- Disable the particles.
	particleEmitter.Enabled = false

	-- Remove the particle emitter after the particles have faded.
	debris:AddItem(particleEmitter, particleEmitter.Lifetime.Max)
end

local function lineOfSight(startingLocation: CFrame, targetPosition: CFrame, targetCharacter)
	local direction = CFrame.lookAt(startingLocation.Position, targetPosition.Position).LookVector.Unit
	local raycastResult = workspace:Raycast(startingLocation.Position, direction * 254, raycastParams)
	if not raycastResult then
		return false
	else
		return raycastResult.Instance:IsDescendantOf(targetCharacter)
	end
end

local function explode(partToExplode)
	
	local explosionPoint = Instance.new("Attachment")
	explosionPoint.Parent = partToExplode
	
	local zndex = math.max(1, partToExplode.Size.Magnitude / 1000)
	for _,particle in ipairs(explosionParticles:GetChildren()) do
		local particleClone: ParticleEmitter = particle:Clone()
		particleClone.ZOffset = particle.ZOffset * zndex
		particleClone.Parent = explosionPoint
		particleClone:Emit(2)
		debris:AddItem(particleClone, particleClone.Lifetime.Max)
	end
end


--- Hazard Effects ---
-- Explosion.
local function toggleBarrel(barrel: Instance, shouldBeVisible: boolean)
	
	-- Attempt to locate all relevent parts.
	local bars = barrel:FindFirstChild("Meshes/BarelBars")
	local body = barrel:FindFirstChild("Meshes/BarelMain")
	local top = barrel:FindFirstChild("Meshes/BarelTop")
	
	-- Switch the visibility and colideability of the parts.
	if shouldBeVisible then
		
		-- Show all relevant parts.
		if bars then
			
			-- Toggle can collide.
			bars.CanCollide = true
			
			-- Tween the transparency.
			tweenService:Create(bars, barrelTween, {
				Transparency = 0
			}):Play()
		end
		
		if body then

			-- Toggle can collide.
			body.CanCollide = true

			-- Tween the transparency.
			tweenService:Create(body, barrelTween, {
				Transparency = 0
			}):Play()
		end
		
		if top then

			-- Toggle can collide.
			top.CanCollide = true

			-- Tween the transparency.
			tweenService:Create(top, barrelTween, {
				Transparency = 0
			}):Play()
		end
	else
		
		-- Hide all relevant parts.
		if bars then
			bars.Transparency = 1
			bars.CanCollide = false
		end
		
		if body then
			body.Transparency = 1
			body.CanCollide = false
		end
		
		if top then
			top.Transparency = 1
			top.CanCollide = false
		end
	end
end

local function applyBurnVFX(character: Instance, removing: boolean)
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and not removing then
		
		-- Destroy existing SFX.
		local burningSFXClone = humanoidRootPart:FindFirstChild("Fire burning")
		if burningSFXClone then 
			burningSFXClone:Destroy() 
		end
		
		-- Initial burn SFX.
		local initialBurnSFXClone = initialBurnSFX:Clone()
		initialBurnSFXClone.Parent = humanoidRootPart
		initialBurnSFX:Play()
		debris:AddItem(initialBurnSFXClone, initialBurnSFXClone.TimeLength)
		
		local burningSFXClone = burningSFX:Clone()
		burningSFXClone.Parent = humanoidRootPart
		burningSFXClone:Play()
		tweenService:Create(burningSFXClone, burningTween, {
			Volume = 0	
		}):Play()
		debris:AddItem(burningSFXClone, burnDuration)
	end
	
	for _,possiblePart in ipairs(character:GetChildren()) do
		
		-- SKip part the part if it isn't a part.
		if not possiblePart:IsA("Part") then
			continue
		end
		
		local fireEffectClone : ParticleEmitter = possiblePart:FindFirstChild("Fire")
		if fireEffectClone then			
			if removing then
				fireEffectClone:Destroy()
			else
				removeParticles(fireEffectClone)				
			end
		end
		
		-- Clear out VFX if it 
		if not removing then
			local fireEffectClone = fireParticles:Clone()
			fireEffectClone.Parent = possiblePart
			fireEffectClone.Enabled = true
		end
	end
	
	-- Remove the effects automatically.
	if not removing then
		task.delay(burnDuration * 0.75, function ()
			applyBurnVFX(character, true)
		end)
	end
end

local function activateBarrelHazard(barrel: Instance, cooldown: number?)
	
	local body = barrel:FindFirstChild("Meshes/BarrelMain")
	if not body or not body:IsA("MeshPart") then
		return
	end
	
	-- Decide how long it will take for the barrel to explode.
	local randomTime = math.random(1, 5)
	
	-- Clone in the burning SFX and wait the random duration
	local burningSound = burningSFX:Clone()
	burningSound.Parent = body
	burningSFX.Volume = .7
	burningSFX:Play()
	debris:AddItem(burningSound, randomTime)

	local fireEffectClone = fireParticles:Clone()
	fireEffectClone.Parent = body
	task.delay(randomTime, function ()
		fireEffectClone.Enabled = false
	end)
	
	debris:AddItem(fireEffectClone, fireEffectClone.Lifetime.Max + randomTime)
	task.wait(randomTime)
	
	-- Explode the oil barrel and damage nearby players.
	explode(body)
	
	-- Clone the SFX and play it.
	local explosionSFXClone = oilExplosionSFX:Clone()
	explosionSFXClone.Parent = body
	explosionSFXClone:Play()
	debris:AddItem(explosionSFXClone, explosionSFXClone.TimeLength)
	
	-- Get the parts in the radius of the explosion.
	local partsBoundInRadius = workspace:GetPartBoundsInRadius(body.CFrame.Position, explosionRadius, explosionOverlapParams)
	local charactersInRadius = extractCharacters(partsBoundInRadius)
	
	-- Apply relevant effects to characters in the radius.
	for _, character in ipairs(charactersInRadius) do
		
		-- Get the humanoid root part.
		local humanoidRootPart: Part = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			continue
		end
		
		-- Verify that the target can be seen.
		local targetVisible = lineOfSight(body.CFrame, humanoidRootPart.CFrame, character)
		if not targetVisible then
			continue
		end
		
		-- Get the distance to the player and apply damage based on that fact.
		local distance = (humanoidRootPart.CFrame.Position - body.CFrame.Position).Magnitude
		local baseDamage = -maxExplosionDamage / math.max(1, distance)
		local player = players:GetPlayerFromCharacter(character)
		
		healthManager:adjustHealth(player, baseDamage)
		
		-- If the player is close enough, burn them.
		if distance <= burnRadius then
			
			-- Add the burn VFX.
			applyBurnVFX(character, false)
			
			-- Give the burn effect.
			giveEffectEvent:Fire(player, effects.Burning, burnDuration)
		end
	end
	
	-- Toggle the state of the barrel.
	toggleBarrel(barrel, false)
	
	-- Wait the cooldown, then toggle the barrel once again.
	task.wait(cooldown or defaultCooldown)
	toggleBarrel(barrel, true)
end

local function toggleElectricalVFX(hazardPart, removing: boolean)
	
	if removing then
		
		-- Remote the SFX if present.
		local sfx = hazardPart:FindFirstChild("Failure")
		if sfx then
			
			-- Tween the volume down and then remove it.
			tweenService:Create(sfx, burningTween, {
				Volume = 0
			}):Play()
			debris:AddItem(sfx, burningTween.Time)
		end
		
		-- Remove the light point.
		local lightPointClone = hazardPart:FindFirstChild("LightPoint")
		if lightPointClone then
			lightPointClone:Destroy()
		end
		
		-- Remove the particles.
		local boltParticleClone = hazardPart:FindFirstChild("Bolts")
		if boltParticleClone then
			removeParticles(boltParticleClone)
		end
		
		local boltParticle2Clone = hazardPart:FindFirstChild("Bolts2")
		if boltParticle2Clone then
			removeParticles(boltParticle2Clone)
		end
		
		local cloudParticleClone = hazardPart:FindFirstChild("Cloud")
		if cloudParticleClone then
			removeParticles(cloudParticleClone)
		end
	else
		
		-- Calculate the size multiplier.
		local qttyMultiplier = math.max(1, hazardPart.Size.Magnitude / 250)

		-- Clone the SFX over.
		local failureClone = FailureSFX:Clone()
		failureClone.Parent = hazardPart
		failureClone:Play()
		
		-- Clone the light point.
		local lightPointClone = lightPointElectrical:Clone()
		lightPointClone.Parent = hazardPart
		
		-- Clone the SFX.
		local boltParticleClone = boltParticles:Clone()
		boltParticles.Rate *= qttyMultiplier
		boltParticleClone.Parent = hazardPart
		
		local boltParticle2Clone = boltParticles2:Clone()
		boltParticle2Clone.Rate *= qttyMultiplier
		boltParticle2Clone.Parent = hazardPart
		
		local cloudParticleClone = cloudParticlesElectrical:Clone()
		cloudParticleClone.Rate *= qttyMultiplier
		cloudParticleClone.Parent = hazardPart
	end
end

local function electricalPartTouched(part: BasePart)
	
	-- Verify that the part is a player.
	local possibleCharacter = part.Parent
	local maybePlayer = players:GetPlayerFromCharacter(possibleCharacter)
	if not maybePlayer then 
		return
	end
	
	-- If the player was zapped recently, then return.
	if collectionService:HasTag(maybePlayer, electricalHitTag) then
		return
	end
	
	-- The player has been zapped.
	collectionService:AddTag(maybePlayer, electricalHitTag)
	task.delay(electricalTagRemovalTime, function ()
		collectionService:RemoveTag(maybePlayer, electricalHitTag)
	end)
	
	-- Damage the player.
	healthManager:adjustHealth(maybePlayer, -zapDamage)
	
	-- Clone over the SFX.
	local sfxClone = zapSFX:Clone()
	sfxClone.Parent = part
	sfxClone:Play()
	debris:AddItem(sfxClone, sfxClone.TimeLength)
end

local function activateElectricalHazard(hazardPart, cooldown: number?)
	
	-- Apply the VFX.
	toggleElectricalVFX(hazardPart, false)
	
	-- Setup the zap event.
	local partTouchedEvent = hazardPart.Touched:Connect(electricalPartTouched)
	
	-- Wait a bit, then explode.
	task.wait(electricalExplodeTime)
	
	-- Explode the part.
	explode(hazardPart)
	
	-- Play an explosion sound effect.
	local explosionSFXClone = electricalExplosion:Clone()
	explosionSFXClone.Parent = hazardPart
	explosionSFXClone:Play()
	debris:AddItem(explosionSFXClone, explosionSFXClone.TimeLength)
	
	-- Get the parts in the radius of the explosion.
	local partsBoundInRadius = workspace:GetPartBoundsInRadius(hazardPart.CFrame.Position, electricalExplosionRadius, explosionOverlapParams)
	local charactersInRadius = extractCharacters(partsBoundInRadius)

	-- Apply relevant effects to characters in the radius.
	for _, character in ipairs(charactersInRadius) do

		-- Get the humanoid root part.
		local humanoidRootPart: Part = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			continue
		end

		-- Verify that the target can be seen.
		local targetVisible = lineOfSight(hazardPart.CFrame, humanoidRootPart.CFrame, character)
		if not targetVisible then
			continue
		end
		
		-- Get the distance to the player and apply damage based on that fact.
		local distance = (humanoidRootPart.CFrame.Position - hazardPart.CFrame.Position).Magnitude
		local baseDamage = -maxElectricalExplosionDamage / math.max(1, distance)
		local player = players:GetPlayerFromCharacter(character)

		healthManager:adjustHealth(player, baseDamage)
	end
	
	-- Remove the VFX and connections.
	task.wait(cooldown or defaultCooldown)
	toggleElectricalVFX(hazardPart, true)
	partTouchedEvent:Disconnect()
end

local function gasPartTouched(part: BasePart)
	
	-- Verify that the part is a player.
	local possibleCharacter = part.Parent
	local maybePlayer = players:GetPlayerFromCharacter(possibleCharacter)
	if not maybePlayer then 
		return
	end

	-- If the player was hit recently, then return.
	if collectionService:HasTag(maybePlayer, gasHitTag) then
		return
	end

	-- The player has been hit.
	collectionService:AddTag(maybePlayer, gasHitTag)
	task.delay(gasTagRemovalTime, function ()
		collectionService:RemoveTag(maybePlayer, gasHitTag)
	end)
	
	-- Damage the player.
	healthManager:adjustHealth(maybePlayer, gasHitDamage)
	
	-- Inflict bleed on the player.
	giveEffectEvent:Fire(maybePlayer, effects.Bleeding, bleedEffectDuration)
end

local function activatePipeHazard(hazardPart, cooldown: number?)
	
	-- Locate the attachment for the particles to be located in.
	local particlePart = hazardPart:FindFirstChild("Attachment")
	if not particlePart then
		hazardPart:Destroy()
		return
	end
	
	-- Clone the VFX over to the part.
	local particleClone = gasParticle:Clone()
	particleClone.Parent = particlePart
	
	local gasSFXClone = gasLeakSFX:Clone()
	gasSFXClone.Parent = hazardPart
	gasSFXClone:Play()
	
	-- Damage the player on hit.
	local hitConnection = hazardPart.Touched:Connect(gasPartTouched)
	
	task.wait(gasDuration)
	
	-- Undo the VFX.
	gasSFXClone:Destroy()
	removeParticles(particleClone)
	hitConnection:Disconnect()
	
	-- Wait the cooldown.
	task.wait(cooldown or defaultCooldown)
end

local function activateHazard(hazardPart: Instance, cooldown: number?)
	
	-- Tag the item to prevent it from being activated multiple times.
	collectionService:AddTag(hazardPart, activeTag)

	-- Run different logic depending on the type of hazard.
	if hazardPart.Name == "Oil barrel" then
		activateBarrelHazard(hazardPart, cooldown)
	elseif hazardPart.Name == "Shock Zone" or hazardPart.Parent	== electricalZones then
		activateElectricalHazard(hazardPart, cooldown)
	elseif hazardPart.Name == "ToxicFumes" then
		activatePipeHazard(hazardPart, cooldown)
	end
	
	-- Allow the object to be used again.
	collectionService:RemoveTag(hazardPart, activeTag)
end

-- Spawning Hazards.
local function getNearbyHazards(searchLocation: CFrame, range: number): {Instance}
	
	local eHazards = {}
	local partsBoundInRadius = workspace:GetPartBoundsInRadius(searchLocation.Position, range, overlapParams)
	for _,instance in ipairs(partsBoundInRadius) do
		
		local partParent = instance.Parent
		if partParent:IsA("Folder") then
			
			-- Verify the part is not already active.
			if collectionService:HasTag(instance, activeTag) then
				continue
			end
			
			-- Add the part to the list of potential zones.
			table.insert(eHazards, instance)
		else
			
			-- Verify that the parent has not already been added.
			if table.find(eHazards, partParent) then
				continue
			end

			-- Verify that the hazard is not active.
			if collectionService:HasTag(partParent, activeTag) then
				continue
			end

			-- Add the hazard to the list of found hazards.
			table.insert(eHazards, partParent)
		end
	end
	
	-- Return the list of hazards.
	return eHazards
end

local function spawnHazardNearPlayer(player: Player, range: number?, numHazards: number?, cooldown: number?)
	
	-- Get the player's character.
	local character = player.Character
	if not character then
		return
	end
	
	-- Get the player's position.
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local playerPosition
	if not humanoidRootPart then
		return
	end
	
	playerPosition = humanoidRootPart.CFrame
	
	-- Get the nearby hazards.
	local nearbyHazards = getNearbyHazards(playerPosition, defaultRange)
	if #nearbyHazards < 1 then
		return
	end
	
	local hazardsToActivate = {}
	
	-- Select the hazards to spawn.
	local hazardsToSpawn = numHazards or 1
	for i=1, math.min(hazardsToSpawn, #nearbyHazards) do
		
		-- Select a random hazard.
		local randomIndex = math.random(1, #nearbyHazards)
		local selectedHazard = nearbyHazards[randomIndex]
		table.insert(hazardsToActivate, selectedHazard)
		
		-- Activate the hazard.
		task.spawn(activateHazard, selectedHazard, cooldown)
		
		-- Remove the hazard from the list.
		table.remove(nearbyHazards, randomIndex)
	end
end

-- Event Functions --
local function spawnNaturalHazard(range: number?, numHazards: number?, cooldown: number?)
	
	-- Get a random player.
	local players = players:GetPlayers()
	local randomIndex = math.random(1, #players)
	local randomPlayer = players[randomIndex]
	
	-- Spawn the hazards.
	spawnHazardNearPlayer(randomPlayer, range, numHazards, cooldown)
end

-- Events --
spawnNaturalHazardEvent.Event:Connect(spawnNaturalHazard)
spawnNaturalHazardForPlayerEvent.Event:Connect(spawnHazardNearPlayer)