-- Services --
local serverStorage = game:GetService("ServerStorage")
local runService = game:GetService("RunService")
local badgeService = game:GetService("BadgeService")
local players = game:GetService("Players")

-- Modules --
local framework = serverStorage:WaitForChild("Framework")
local frameworkModules = framework:WaitForChild("Modules")
local effectData = require(frameworkModules:WaitForChild("Effects"))

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")
local effectEvents = bindableEvents:WaitForChild("Effect System")
local giveEffectEvent = effectEvents:WaitForChild("GiveEffectEvent")

-- Bindable Functions --
local bindableFunctions = framework:WaitForChild("Bindable Functions")
local effectFunctions = bindableFunctions:WaitForChild("Effect System")
local hasEffectFunction = effectFunctions:WaitForChild("HasEffect")
local getActiveEffectsFunction = effectFunctions:WaitForChild("GetActiveEffects")

-- Settings --
local ticksPerSecond = 5
local healthThreshold = 25
local overhealDecayPerSecondPerHealthThreshold = 1.5
local naturalRegenPerSecond = 1

local overhealCutoff = 30

local adrenalinBadgeId = 558070475611806
local adrenalinHealthThreshold = 15
local adrenalinDuration = 35
local adrenalinMinHealth = 1

-- Storage --
local tickTime = 1/ticksPerSecond
local currentTime = 0

local adrenalinData = {}

-- Main Module --
local healthManager = {}
healthManager.__index = healthManager

-- Functions --
-- Utility --
local function getHealthObject(plr: Player)
	local char = plr.Character
	if not char then 
		return
	end
	
	return char, char:FindFirstChild("Health Stats") 
end

local function resetPlrServerData(plr: Player)
	adrenalinData[plr] = nil
end

-- Effect Management --
local function shouldApplyBleadDamage(plr: Player, activeEffects: {string})
	
	if table.find(activeEffects, "Deep Wounds") then
		giveEffectEvent:Fire(plr, effectData.Bleeding, 2)
	end
	
	if table.find(activeEffects, "Bleedout") then
		giveEffectEvent:Fire(plr, effectData.Bleeding, 3)
		giveEffectEvent:Fire(plr, effectData["Deep Wounds"], 1)
	end
	
	if table.find(activeEffects, "Exsanguine Collapse") then
		giveEffectEvent:Fire(plr, effectData.Bleeding, 5)
		giveEffectEvent:Fire(plr, effectData["Deep Wounds"], 3)
		giveEffectEvent:Fire(plr, effectData.Bleedout, 1)
	end
end

local function convertDamageToBleed(damage: number)
	
	local absDamage = math.abs(damage)
	
	if absDamage < 30 then
		return effectData.Bleeding, absDamage / 5
	elseif absDamage < 50 then
		return effectData["Deep Wounds"], absDamage / 4
	elseif absDamage < 70 then
		return effectData.Bleedout, absDamage / 3
	else
		return effectData["Exsanguine Collapse"], absDamage / 2
	end
end

-- General Health Management --
local function changeHealth(plr: Player, healthObj: ConfigService, adjustment: number, damageMultiplier: number, health: number, maxHealth: number, overheal: boolean?, criticalHit: boolean?)

	local finalMultiplier = damageMultiplier
	if criticalHit then
		finalMultiplier = 1
	end

	-- Adjust the health differentl'y based on whether or not the player is being healed. 
	local finalAdjustment = adjustment
	if math.sign(adjustment) > 0 then

		-- If overflow isn't enabled, clamp the health to the max health.
		if health + adjustment >= maxHealth and not overheal then

			-- No healing will be done.
			finalAdjustment = 0

			if health < maxHealth then
				healthObj:SetAttribute("Health", maxHealth)
			end
			
			return
		end
	else
		
		-- Multiply the adjustment by the damage multiplier
		finalAdjustment *= finalMultiplier
		
		-- Prevent oveerheal decay from dropping health below full.
		if overheal and health + adjustment <= maxHealth and health > maxHealth then
			healthObj:SetAttribute("Health", maxHealth)
			return
		end
	end

	-- If the health change is negative (damage), check if the player has bleed and update it.
	local plrAdrenalinData = adrenalinData[plr]
	if adjustment < 0 and not criticalHit and (not plrAdrenalinData or not plrAdrenalinData.active) then
		
		-- Get the player's active effects.
		local activeEffects = getActiveEffectsFunction:Invoke(plr)
		shouldApplyBleadDamage(plr, activeEffects)
		
		-- If the player has sanguine rot, deal bleed damage instead.
		if table.find(activeEffects, "Sanguine Rot") then
			local effect, duration = convertDamageToBleed(finalAdjustment)
			giveEffectEvent:Fire(plr, effect, duration)
		else
			
			-- Adjust health.
			healthObj:SetAttribute("Health", health + finalAdjustment)
		end
	elseif (not plrAdrenalinData or not plrAdrenalinData.active) then
		
		-- Adjust health.
		healthObj:SetAttribute("Health", health + finalAdjustment)
	elseif plrAdrenalinData and plrAdrenalinData.active and adjustment < 0 then
		plrAdrenalinData.totalDamage += finalAdjustment
	else
		healthObj:SetAttribute("Health", health + finalAdjustment)
	end
	
	-- Give the player adrenalin if need be.
	if plrAdrenalinData and finalAdjustment < 0 and plrAdrenalinData.unlocked and not plrAdrenalinData.active and not plrAdrenalinData.onCooldown and ((healthObj:GetAttribute("Health") <= adrenalinHealthThreshold or health < adrenalinHealthThreshold))then
		
		-- Toggle cooldown.
		plrAdrenalinData.onCooldown = true
		plrAdrenalinData.active = true

		-- Apply the adrenalin effec to the player.
		giveEffectEvent:Fire(plr, effectData["Adrenalin"], adrenalinDuration)
		
		-- Remove the effect.
		task.delay(adrenalinDuration, function ()
			
			-- Store the player's current health.
			local plrHealth = healthObj:GetAttribute("Health")
			
			-- Calculate the total amount of damage applied to the player.
			local totalDamage = plrAdrenalinData.totalDamage
			local remainingHealth = plrHealth + totalDamage
			if remainingHealth < adrenalinMinHealth then
				totalDamage = -(plrHealth - (2 * adrenalinMinHealth))
				print(totalDamage)
			end
			
			-- Toggle cooldowns.
			plrAdrenalinData.active = false
			
			-- Adjust health.
			changeHealth(plr, healthObj, totalDamage, 1, plrHealth, maxHealth, false, true)
		end)
	end
	
	-- Return if the player is dead.
	if healthObj:GetAttribute("Health") <= 0 or health <= 0 then
		
		if healthObj:GetAttribute("CanDie") and plrAdrenalinData.unlocked then
			
			-- Use the unlocked status to prevent several resets to be queued.
			plrAdrenalinData.unlocked  = false
			
			-- Revert all relevent data to an original state.
			task.delay(5, function ()
				plrAdrenalinData.unlocked = true
				plrAdrenalinData.onCooldown = false
				plrAdrenalinData.active = false
				plrAdrenalinData.totalDamage = 0
			end)
		end
		
		return true
	end
end

function healthManager:adjustHealth(plr: Player, healthAdjustment: number, overheal: boolean?, criticalhit: boolean?)

	local char, health = getHealthObject(plr)
	
	-- Handle if the player hasn't recieved a health ovject.
	if not health then
		local humanoid = char:FindFirstChildOfClass("Humanoid")

	-- Warn the devs if something goes wrong.
		if not humanoid then 
			warn("Attempted to damage null humanoid player.")
			return
		end

		-- Adjust health. Roblox autoclamps health so this will work out fine.
		humanoid.Health += healthAdjustment
		return
	end

	-- Get all necessary values.
	local damageMultiplier = health:GetAttribute("DamageMultiplier")
	local currentHealth = health:GetAttribute("Health")
	local maxHealth = health:GetAttribute("MaxHealth")

	-- Adjust the player's healtj.
	local dead = changeHealth(plr, health, healthAdjustment, damageMultiplier, currentHealth, maxHealth, overheal, criticalhit)
	
	-- Attempt to kill the player if they should be dead.
	if dead then

		-- If the player can die, kill their humanoid.
		if health:GetAttribute("CanDie") then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			humanoid.Health = 0
		end
	end
end

function healthManager:isOverhealed(plr: Player): boolean
	local char, health = getHealthObject(plr)
	
	-- if there isn't a custom health obejct, they will not be overhealed.
	if not health then 
		return false
	end
	
	local currentHealth, maxHealth = health:GetAttribute("Health"), health:GetAttribute("MaxHealth")
	return (currentHealth - maxHealth) > 10e-6
end

function healthManager:getOverheal(plr)
	
	local char, health = getHealthObject(plr)

	-- if there isn't a custom health obejct, they will not be overhealed.
	if not health then 
		return false
	end

	-- Get necessary attributes and determine the amount of overheal.
	local currentHealth, maxHealth = health:GetAttribute("Health"), health:GetAttribute("MaxHealth")
	if currentHealth < maxHealth then
		return 0
	else
		return currentHealth-maxHealth
	end
end

function healthManager:isFullyHealed(plr: Player): boolean

	local char, health = getHealthObject(plr)

	--  Return if there is no character
	if not char then
		return true -- No character to heal.
	end
	
	-- if there isn't a custom health obejct, they will not be overhealed.
	if not health then 
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		return humanoid.Health == humanoid.MaxHealth
	end

	local currentHealth, maxHealth = health:GetAttribute("Health"), health:GetAttribute("MaxHealth")
	return currentHealth == maxHealth
end

local function setupAdrenalinData(plr: Player)
	
	-- Attempt to get whether or not the player 
	local hasBadge
	local success = pcall(function ()
		hasBadge = badgeService:UserHasBadgeAsync(plr.UserId, adrenalinBadgeId)
	end)
	
	if not success then
		return
	end
		
	local plrData = {
		unlocked = hasBadge,
		active = false,
		onCooldown = false,
		totalDamage = 0
	}
	
	adrenalinData[plr] = plrData
end

local function periodic(deltaTime)
	
	-- Update the current time.
	currentTime += deltaTime
	
	-- Return if it is not time to tick the game.
	if currentTime < tickTime then
		return
	end
	
	-- Reset the tick time.
	currentTime = 0

	-- Tick the health of each player.
	for _, plr in ipairs(players:GetChildren()) do
		
		-- Verify that we know whether or not the player can have addrenalin.
		local plrAdrenalinData = adrenalinData[plr]
		if not plrAdrenalinData then
			setupAdrenalinData(plr)
		end
		
		-- Ensure the targeted player is in fact a player.
		if not plr:IsA("Player") then
			continue
		end
		
		-- Don't heal the player if they have adrenalin active or is not overhealed.
		if healthManager:isFullyHealed(plr) or plrAdrenalinData.active then
			continue
		end
		
		-- Damage / heal each player acordingly.
		local overheal = healthManager:getOverheal(plr)
		local netOverheal = overheal - overhealCutoff
		if netOverheal > 0 then
			
			-- Calculate and deal the respective overheal damage.
			local overheaalDecay = (math.ceil(netOverheal/healthThreshold) * overhealDecayPerSecondPerHealthThreshold * tickTime)
			if netOverheal - overheaalDecay < 0 then
				overheaalDecay = netOverheal -- Prevent leaving the player with less than the maximum allowed overheal.
			end
			
			healthManager:adjustHealth(plr, -overheaalDecay, true, true) -- Overheal decay can be considered "true damage" it pierces through al ldefense.
		else
			healthManager:adjustHealth(plr, naturalRegenPerSecond * tickTime, false)
		end
	end
end

-- Events --
runService.Heartbeat:Connect(periodic)
players.PlayerRemoving:Connect(resetPlrServerData)

-- Return the Module --
return healthManager
