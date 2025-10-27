--[[
NOTICE: THIS IS ONE OF TWO EFFECT MODULES. CHANGES MADE TO THIS MODULE MUST HAVE A CORRESPONDING CHANGE IN THE SERVER EFFECTS MODULE!
THIS SYSTEM EXISTS TO LIMIT DATA SENT FROM SERVER TO CLIENT.

IF YOU HAVE ANY QUESTIONS, PLEASE ASK ME! 

- Lolbit757575
]]

-- Types --
export type effectData = {
	
	-- Informational --
	name: string,
	description: string,
	
	-- Display --
	layoutOrder: number, -- Lower = higher priority, sowing up towards the bottom right corner. negative effects should have a lower layout order than ALL positive effects.
	imageId: string,
	specialBackgroundColor: Color3?
}

export type availableEffects = {
	
	-- Default / Null Effect --
	["Null"]: effectData,
	
	-- Positive Effects --
	["Divine Blessing"]: effectData, -- Dev only effect.
	
	["Regeneration"]: effectData,
	["Regeneration+"]: effectData,
	["Regeneration++"]: effectData,
	
	["Resistance"]: effectData,
	["Resistance+"]: effectData,
	["Resistance++"]: effectData,

	["Endurance"]: effectData,
	["Endurance+"]: effectData,
	["Endurance++"]: effectData,

	-- Negative Effects --
	["Decay"]: effectData,
	["Decay+"]: effectData,
	["Decay++"]: effectData,

	["Burning"]: effectData,

	["Bleeding"]: effectData,
	["Deep Wounds"]: effectData,
	["Bleedout"]: effectData,
	["Exsanguine Collapse"]: effectData,	
	
	["Sanguine Rot"]: effectData,
}

local cleintEffectData: availableEffects = {
	
	["Null"] = {
		name = "Null",
		description = "Effect system error. Please inform a develoepr!",
		
		layoutOrder = -1,
		imageId = "rbxassetid://18431234417"
	},
	
	-- Positive Effects
	["Divine Blessing"] = {
		name = "Divine Blessing",
		description = 
			" - Heals 99 health per second (Can Overheal)" .. 
			"\n - Increasse max health by 999" .. 
			"\n - Reduce damage taken by 75%" .. 
			"\n - Increase max stamina by 5000" .. 
			"\n - Increase movement speed by 200%" ..
			"\n - Increase stamina gain by 500%",
		
		layoutOrder = 1009,
		imageId = "rbxassetid://18431234417"
	},
	
	["Regeneration"] = {
		name = "Regeneration",
		description = " - Heals 5 health per second",

		layoutOrder = 1008,
		imageId = "rbxassetid://131963335014560"
	},
	["Regeneration+"] = {
		name = "Regeneration+",
		description = " - Heals 10 health per second",

		layoutOrder = 1007,
		imageId = "rbxassetid://137234610601112"
	},
	["Regeneration++"] = {
		name = "Regeneration++",
		description = " - Heals 15 health per second (Can Overheal)",

		layoutOrder = 1006,
		imageId = "rbxassetid://77137202035917"
	},
	
	["Resistance"] = {
		name = "Resistance",
		description = " - Decrease damage taken by 10%",

		layoutOrder = 1005,
		imageId = "rbxassetid://98877006470130"
	},
	["Resistance+"] = {
		name = "Resistance+",
		description = " - Decrease damage taken by 25%",

		layoutOrder = 1004,
		imageId = "rbxassetid://117318501363756"
	},
	["Resistance++"] = {
		name = "Resistance++",
		description = " - Decrease damage taken by 50%",

		layoutOrder = 1003,
		imageId = "rbxassetid://121954130067583"
	},
	
	["Endurance"] = {
		name = "Endurance",
		description = " - Increase speed by 15%" .. 
			"\n - Decrease stamina usage by 5%" .. 
			"\n - Increase stamina gain by 20%",

		layoutOrder = 1002,
		imageId = "rbxassetid://93536951660835"
	},
	["Endurance+"] = {
		name = "Endurance+",
		description = " - Increase speed by 25%" .. 
			"\n - Decrease stamina usage by 15%" .. 
			"\n - Increase stamina gain by 30%",

		layoutOrder = 1001,
		imageId = "rbxassetid://85978165275995"
	},
	["Endurance++"] = {
		name = "Endurance++",
		description = " - Increase speed by 50%" .. 
			"\n - Decrease stamina usage by 25%" .. 
			"\n - Increase stamina gain by 40%",

		layoutOrder = 1000,
		imageId = "rbxassetid://75345301666523"
	},
	
	["Adrenalin"] = {
		name = "Adrenalin",
		description = " - Dissables natural regeneration." .. 
			"\n - You take zero damage." ..
			"\n - Increase movement speed by 50%" .. 
			"\n - Decrease stamina usage by 70%" ..
			"\n - Increase stamina gain by 25%" ..
			"\n - Increase damage taken by 200%" ..
			"\n \n (All damage taken is applied when this effect ends)",

		layoutOrder = 999,
		imageId = "rbxassetid://127509492935572"
	},
	
	-- Negative Effects --
	["Decay"] = {
		name = "Decay",
		description = " - Take 5 damage per second",

		layoutOrder = 7,
		imageId = "rbxassetid://81412715218504"
	},
	["Decay+"] = {
		name = "Decay+",
		description = " - Take 10 damage per second" .. 
			"\n - Take 25% more damage",

		layoutOrder = 6,
		imageId = "rbxassetid://75650689477983"
	},
	["Decay++"] = {
		name = "Decay++",
		description = " - Take 20 damage per second" ..
			"\n - Take 50% more damage",

		layoutOrder = 5,
		imageId = "rbxassetid://129615577912963"
	},
	
	["Burning"] = {
		name = "Burning",
		description = " - Take 15 damage per second" .. 
			"\n - Increase movement speed by 25%" ..
			"\n - Stamina gain is reduced by 30%",

		layoutOrder = 4,
		imageId = "rbxassetid://106351549531094"
	},
	
	["Bleeding"] = {
		name = "Bleeding",
		description = ' - Take 5 <font color="#EA3B2E">true</font> damage per second' ..
			'\n - Decrease movement speed by 5%',

		layoutOrder = 3,
		imageId = "rbxassetid://134005420726250"
	},
	["Deep Wounds"] = {
		name = "Deep Wounds",
		description = ' - Take 4 <font color="#EA3B2E">true</font> damage per second' ..
			'\n - Decrease movement speed by 20%' .. 
			'\n - Each hit inflicts 2 seconds of <font color="#EA3B2E">bleeding</font>',

		layoutOrder = 2,
		imageId = "rbxassetid://88398988448776"
	},
	["Bleedout"] = {
		name = "Bleedout",
		description = ' - Take 3 <font color="#EA3B2E">true</font> damage per second' ..
			'\n - Increase damage taken by 15%' ..
			'\n - Decrease movement speed by 30%' .. 
			'\n - Each hit inflicts 1 seconds of <font color="#EA3B2E">Deep Wounds</font>' ..
			'\n - Each hit inflicts 3 seconds of <font color="#EA3B2E">bleeding</font>',

		layoutOrder = 1,
		imageId = "rbxassetid://87014709415635"
	},
	["Exsanguine Collapse"] = {
		name = "Exsanguine Collapse",
		description = ' - Take 2 <font color="#EA3B2E">true</font> damage per second' ..
			'\n - Increase damage taken by 30%' ..
			'\n - Decrease max stamina by 100' .. 
			'\n - Increase stamina cost by 100%' .. 
			'\n - Each hit inflicts 1 seconds of <font color="#EA3B2E">Bleedout</font>' ..
			'\n - Each hit inflicts 3 seconds of <font color="#EA3B2E">Deep Wounds</font>' ..
			'\n - Each hit inflicts 5 seconds of <font color="#EA3B2E">bleeding</font>',

		layoutOrder = 0, 
		imageId = "rbxassetid://125084673959578"
	},
	
	["Sanguine Rot"] = {
		name = '<stroke color="#000000" joins="miter" thickness="1"><font color="#850505">Sanguine Rot</font></stroke>',
		description = ' - Decreases natural regeneration by 80%.' ..
			'\n - Increase damage taken by 150%' ..
			'\n - Increase speed by 10%' .. 
			'\n - Increase stamina usage by 5%' .. 
			'\n - Increase stamina gain by 100%' .. 
			'\n - All damage is taken as <font color="#EA3B2E">bleed damage</font> overtime'..
			'\n \n <font color="#EA3B2E"> (This effect persists after death) </font>',

		layoutOrder = -math.huge, -- Always be in the bottom right corner.
		imageId = "rbxassetid://121550061019750",
		specialBackgroundColor = Color3.fromRGB(133,5,5)
	},
}

return cleintEffectData
