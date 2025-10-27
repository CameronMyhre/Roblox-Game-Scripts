-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local frameworkModules = framework:WaitForChild("Modules")
local healthManager = require(frameworkModules:WaitForChild("Health Manager"))
local effectData = require(frameworkModules:WaitForChild("Effects"))

-- Bindible Events --
local bindableEvents = framework:WaitForChild("Bindable Events")

local playerEvents = bindableEvents:WaitForChild("Player") -- Bindible events folder 
local characterSetupEvent = playerEvents:WaitForChild("CharacterSetup")

local effectEvents = bindableEvents:WaitForChild("Effect System")
local giveEffectEvent = effectEvents:WaitForChild("GiveEffectEvent")
local removeEffectEvent = effectEvents:WaitForChild("RemoveEffectEvent")
local effectAddedEvent = effectEvents:WaitForChild("EffectAddedEvent")
local effectUpdatedEvent = effectEvents:WaitForChild("EffectUpdatedEvent")
local effectRemovedEvent = effectEvents:WaitForChild("EffectRemovedEvent")

-- Bindable Functions --
local bindableFunctions = framework:WaitForChild("Bindable Functions")
local effectFunctions = bindableFunctions:WaitForChild("Effect System")
local hasEffectFunction = effectFunctions:WaitForChild("HasEffect")
local getActiveEffectsFunction = effectFunctions:WaitForChild("GetActiveEffects")

-- Remote Events --
local remoteFramework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = remoteFramework:WaitForChild("Remote Events")
local remoteEffectEvents = remoteEvents:WaitForChild("Effects")
local remoteEffectAddedEvent = remoteEffectEvents:WaitForChild("EffectAdded")
local remoteEffectChangedEvent = remoteEffectEvents:WaitForChild("EffectChanged")
local remoteEffectRemovedEvent = remoteEffectEvents:WaitForChild("EffectRemoved")
local remoteEffectsRemovedEvent = remoteEffectEvents:WaitForChild("EffectsRemoved")

-- Settings --
local baseMaxHealth = 100
local baseHealthChangePerSecond = 0
local baseOverhealChangePerSecond = 0
local baseDamageMultiplier = 1

local baseMaxStamina = 200
local baseSpeedMultiplier = 1
local baseCostMultiplier = 1
local baseGainMultiplier = 1

local tickFrequency = 0.1 -- Seconds required for a tick. This updates things like health and effect expiration.

-- Storage --
local playerEffects = {}
local currentTime = 0
local accumulatedTime = 0

-- Functions --
-- Main Functions --
local function applyTotalEffectChange(plr)
	
	-- Get the player's data.
	local plrData = playerEffects[plr]
	
	local overhealHealthChangePerSecond = 0
	local healthChangePerSecond = 0
	local maxHealthChange = 0
	local damageMultiplierChange = 0
	
	local maxStaminaChange = 0
	local speedMultiplierChange = 0
	local costMultiplierChange = 0
	local gainMultiplierChange = 0
	
	if not plrData then
		return
	end
	
	-- Get all active effects.
	local plrEffects = playerEffects[plr].effects
	for effectName, plrEffectData in pairs(plrEffects) do
		
		-- Make sure the effect exists.
		local effect: effectData.effect = effectData[effectName]
		if not effect then
			playerEffects[plr].effects[effectName] = nil
		end
		
		-- Allow overheal and store health change variables.
		if effect.healthChanges.overhealHealthChange then
			overhealHealthChangePerSecond += effect.healthChanges.healthChangePerSecond
		else
			healthChangePerSecond += effect.healthChanges.healthChangePerSecond
		end
		
		maxHealthChange += effect.healthChanges.maxHealthChange
		damageMultiplierChange += effect.healthChanges.damageMultiplierChange
		
		-- Store stamina change variables.
		maxStaminaChange += effect.movementChanges.maxStaminaChange
		speedMultiplierChange += effect.movementChanges.speedMultiplierChange
		costMultiplierChange += effect.movementChanges.costMultiplier
		gainMultiplierChange += effect.movementChanges.gainMultiplier
	end
	
	-- Apply the new stats.
	plrData.healthChangePerSecond = baseHealthChangePerSecond + healthChangePerSecond
	plrData.overhealChangePerSecond = baseOverhealChangePerSecond + overhealHealthChangePerSecond

	plrData.healthStats:SetAttribute("MaxHealth", baseMaxHealth + maxHealthChange)
	plrData.healthStats:SetAttribute("DamageMultiplier", baseDamageMultiplier + damageMultiplierChange)
	
	plrData.sprintingStats:SetAttribute("MaxStamina", baseMaxStamina + maxStaminaChange)
	plrData.sprintingStats:SetAttribute("SpeedMultiplier", baseSpeedMultiplier + speedMultiplierChange)
	plrData.sprintingStats:SetAttribute("StaminaCostMultiplier", baseCostMultiplier + costMultiplierChange)
	plrData.sprintingStats:SetAttribute("StaminaGainMultiplier", baseGainMultiplier + gainMultiplierChange)
end

local function addEffect(plr, effect: effectData.effect, effectDuration: number)
	
	-- Get the player's data.
	local plrData = playerEffects[plr]
	if not plrData then
		return
	end
	
	-- Verify the effect does not already exist.
	local existingEffect = plrData.effects[effect.name] 

	if existingEffect then
		if effect.stackTime  then
			existingEffect.duration += effectDuration
			plrData.effects[effect.name] = existingEffect
		else

			-- Use the higher of the two durationsand reset the start time of the effect.
			if (existingEffect.duration - (os.time() - existingEffect.applyTime)) > existingEffect.duration then
				existingEffect.duration = effectDuration
			end
			existingEffect.applyTime = currentTime
		end
		
		-- Tell other scripts (and client) that the effect has been updated.
		effectUpdatedEvent:Fire(plr, effect.name, existingEffect.duration)
		remoteEffectChangedEvent:FireClient(plr, effect.name, existingEffect.duration)
		
		-- Return.
		return
	end
	
	-- Add the effect for the given duration.
	local effectData = {
		applyTime = currentTime,
		duration = effectDuration
	}
		
	-- Apply the new stats.
	if effect.healthChanges.overhealHealthChange then
		plrData.overhealChangePerSecond += effect.healthChanges.healthChangePerSecond
	else
		plrData.healthChangePerSecond += effect.healthChanges.healthChangePerSecond
	end
	
	plrData.healthStats:SetAttribute("MaxHealth", plrData.healthStats:GetAttribute("MaxHealth") + effect.healthChanges.maxHealthChange)
	plrData.healthStats:SetAttribute("DamageMultiplier", plrData.healthStats:GetAttribute("DamageMultiplier") + effect.healthChanges.damageMultiplierChange)

	plrData.sprintingStats:SetAttribute("MaxStamina", plrData.sprintingStats:GetAttribute("MaxStamina") + effect.movementChanges.maxStaminaChange)
	plrData.sprintingStats:SetAttribute("SpeedMultiplier", plrData.sprintingStats:GetAttribute("SpeedMultiplier") + effect.movementChanges.speedMultiplierChange)
	plrData.sprintingStats:SetAttribute("StaminaCostMultiplier", plrData.sprintingStats:GetAttribute("StaminaCostMultiplier") + effect.movementChanges.costMultiplier)
	plrData.sprintingStats:SetAttribute("StaminaGainMultiplier", plrData.sprintingStats:GetAttribute("StaminaGainMultiplier") + effect.movementChanges.gainMultiplier)
	
	-- Add the effect data.
	plrData.effects[effect.name] = effectData
	
	-- Fire events to tell other devices that this effect has been added.
	effectAddedEvent:Fire(plr, effect.name, effectData.duration)
	remoteEffectAddedEvent:FireClient(plr, effect.name, effectData.duration)
end

local function removeEffect(plr, effect: effectData.effect, bulkRemoval: boolean?)

	-- Get the player's data.
	local plrData = playerEffects[plr]
	if not plrData then
		return
	end

	-- Verify the effect does not already exist.
	local existingEffect = plrData.effects[effect.name] 
	if not existingEffect then
		return
	end

	-- Revert the stat changes.
	if effect.healthChanges.overhealHealthChange then
		plrData.overhealChangePerSecond -= effect.healthChanges.healthChangePerSecond
	else
		plrData.healthChangePerSecond -= effect.healthChanges.healthChangePerSecond
	end

	plrData.healthStats:SetAttribute("MaxHealth", plrData.healthStats:GetAttribute("MaxHealth") - effect.healthChanges.maxHealthChange)
	plrData.healthStats:SetAttribute("DamageMultiplier", plrData.healthStats:GetAttribute("DamageMultiplier") - effect.healthChanges.damageMultiplierChange)

	plrData.sprintingStats:SetAttribute("MaxStamina", plrData.sprintingStats:GetAttribute("MaxStamina") - effect.movementChanges.maxStaminaChange)
	plrData.sprintingStats:SetAttribute("SpeedMultiplier", plrData.sprintingStats:GetAttribute("SpeedMultiplier") - effect.movementChanges.speedMultiplierChange)
	plrData.sprintingStats:SetAttribute("StaminaCostMultiplier", plrData.sprintingStats:GetAttribute("StaminaCostMultiplier") - effect.movementChanges.costMultiplier)
	plrData.sprintingStats:SetAttribute("StaminaGainMultiplier", plrData.sprintingStats:GetAttribute("StaminaGainMultiplier") - effect.movementChanges.gainMultiplier)
	
	-- Tell other scripts that the effect is being removed.
	effectRemovedEvent:Fire(plr, effect)
	if not bulkRemoval then
		remoteEffectRemovedEvent:FireClient(plr, effect.name)
	end
	
	-- Remove effect data representation.
	plrData.effects[effect.name] = nil
end

-- Setup Functions --
local function setupPlrData(plr: Player)
	
	-- Return the player data object.
	local plrData = {}
	plrData.effects = {}
	plrData.healthChangePerSecond = 0
	plrData.overhealChangePerSecond = 0
	
	-- Toggle the setup flag.
	plrData.setup = false
	
	return plrData
end

-- Utility Functions --
-- Remove all effects that should expire on death, using removeEffect so stats are reverted.
local function removeDeathExpiringEffects(plr: Player)
	local plrData = playerEffects[plr]
	if not plrData then return end

	-- snapshot to avoid mutating while iterating
	local snapshot = {}
	for effectName in pairs(plrData.effects) do
		snapshot[effectName] = true
	end
	
	-- Store the removed effect names to send to the client.
	local removedEffectNames = {}
	
	-- Remove all effects that do not persist after death.
	for effectName in pairs(snapshot) do
		local doesEffectExist: effectData.effect = effectData[effectName]
		
		-- If the effect definition is missing or marked non-persistent, remove it.
		if (not doesEffectExist) or (not doesEffectExist.persistAfterDeath) then
			if doesEffectExist then
				table.insert(removedEffectNames, effectName)
				removeEffect(plr, doesEffectExist, true)
			else
				
				-- Unknown effect: just drop it from the table.
				plrData.effects[effectName] = nil
			end
		end
	end
	
	-- Send the client the list of removed effects.
	remoteEffectsRemovedEvent:FireClient(plr, removedEffectNames)
end

-- Event Functions --
local function periodic(deltaTime: number)
	
	-- Increment the current time.
	currentTime += deltaTime
	
	-- Increment the accumulated time.
	accumulatedTime += deltaTime
	
	-- If the accumulated time is not enough to update the GUI, return.
	if accumulatedTime < tickFrequency then
		return
	end
	
	-- Update effects and health.
	for plrObject, plrData in playerEffects do
		
		-- Skip the player if the data is not yet ready.
		if not plrData.setup then continue end

		-- Tick health
		healthManager:adjustHealth(plrObject, plrData.healthChangePerSecond * accumulatedTime, false, true)
		healthManager:adjustHealth(plrObject, plrData.overhealChangePerSecond * accumulatedTime, true, true)

		-- Expire effects using a snapshot to avoid mutating during iteration
		local snapshot = table.clone(plrData.effects)
		for effectName, props in pairs(snapshot) do
			if currentTime >= (props.applyTime + props.duration) then
				local effectExists = effectData[effectName]
				if effectExists then 
					removeEffect(plrObject, effectExists) 
				else 
					plrData.effects[effectName] = nil 
				end
			end
		end
	end
	
	-- Reset the accumulated time
	accumulatedTime = 0
end

local function setupPlayerData(plr: Player)
	
	local hasData = playerEffects[plr]
	local plrData
	if not hasData then
		plrData = setupPlrData(plr)
	else
		plrData = playerEffects[plr]
	end
	
	-- Store character specific settings.
	plrData.character = plr.Character
	plrData.healthStats = plrData.character:FindFirstChild("Health Stats")
	plrData.sprintingStats = plrData.character:FindFirstChild("Sprinting Stats")
	
	-- Set the data.
	playerEffects[plr] = plrData

	-- Clear effects that expire upon death.
	local humanoid = plrData.character:FindFirstChildOfClass("Humanoid")
	humanoid.Died:Once(function()
		
		-- Remove death expiring effects.
		removeDeathExpiringEffects(plr)
		
		-- Hard reset scalar accumulators and base attributes (guards if stats still exist at this point).
		plrData.healthChangePerSecond = baseHealthChangePerSecond
		plrData.overhealChangePerSecond = baseOverhealChangePerSecond

		if plrData.healthStats then
			plrData.healthStats:SetAttribute("MaxHealth", baseMaxHealth)
			plrData.healthStats:SetAttribute("DamageMultiplier", baseDamageMultiplier)
		end
		if plrData.sprintingStats then
			plrData.sprintingStats:SetAttribute("MaxStamina", baseMaxStamina)
			plrData.sprintingStats:SetAttribute("SpeedMultiplier", baseSpeedMultiplier)
			plrData.sprintingStats:SetAttribute("StaminaCostMultiplier", baseCostMultiplier)
			plrData.sprintingStats:SetAttribute("StaminaGainMultiplier", baseGainMultiplier)
		end

		-- Re-aggregate any effects that *do* persist after death (if you use those).
		applyTotalEffectChange(plr)
		
		-- Toggle the setup flag.
		playerEffects[plr].setup = false
	end)	
	
	-- Update stats if necessary.
	if next(playerEffects[plr].effects) ~= nil then
		applyTotalEffectChange(plr)
	end

	-- Toggle the setup flag.
	playerEffects[plr].setup = true
end

-- Prevent health updates after the player leaves. Also removes all effects.
local function clearPlrData(plr: Player)
	effectData[plr] = nil
	playerEffects[plr] = nil
end

local function hasEffect(plr: Player, effect: effectData.effect): boolean
	
	-- Get the player's data.
	local plrData = playerEffects[plr]
	if not plrData then
		return false	
	end
	
	-- Return whether or not an effect exists
	return plrData.effects[effect.name] ~= nil
end

local function getActiveEffects(plr: Player, effects: {effectData.effect})

	-- Get the player's data.
	local plrData = playerEffects[plr]
	if not plrData then
		return {}
	end
	
	-- Loop through each effect and verify whether or not the player has them.
	local activeEffects = {}
	for effectName in pairs( plrData.effects) do
		table.insert(activeEffects, effectName)
	end
	
	-- Return the complete array.
	return activeEffects
end

-- Events --
characterSetupEvent.Event:Connect(setupPlayerData)
runService.Heartbeat:Connect(periodic)
players.PlayerRemoving:Connect(clearPlrData)

giveEffectEvent.Event:Connect(addEffect)
removeEffectEvent.Event:Connect(removeEffect) -- addEffect(game.Players.lolbit757575, effectData["Bleeding"], 5)

hasEffectFunction.OnInvoke = hasEffect
getActiveEffectsFunction.OnInvoke = getActiveEffects
