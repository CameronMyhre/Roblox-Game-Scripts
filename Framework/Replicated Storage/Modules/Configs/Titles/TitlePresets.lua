-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local configModules = modules:WaitForChild("Configs")
local titleModules = configModules:WaitForChild("Titles")
local titleRequirements = require(titleModules:WaitForChild("TitleRequirements"))

-- Types --
export type titlePresetType = {
	
	-- Data Ownership Values --
	requirementType: titleRequirements.titleRequirementType,
	requiredGroupRanks: {number}?,									-- The list of group ranks that need to be owned to have this title.
	requiredBadges: {number}?,										-- The list of badge ids that need to be owned to have this title.
	requiredGamepasses: {number}?,									-- The list of gamepasses that need to be owned in order for this title to be displayed.

	-- Tag Priority --
	priority: number, 												-- Determines which tag tag is displayed if multiple are owned.
	
	-- Tag Settings --
	title: string,	  												-- [title]: [username]: [message]
	tagColor: Color3, 												-- The color that the title will be displayed as.

	strokeThickness:  string, 										-- The thickness of the border surrounding the text. Don't use this too often, since it persists after chat fade. 
	strokeColor: Color3, 												-- The color of the stroke surrounding the title.
	fontType: string,												-- The font the player's text will be displayed in.
	chatColor: Color3,												-- The color of the player's text.
	
	-- Overhead GUI Settings --
	overheadGui: boolean,											-- Determines if the overhead gui is enabled.
	overheadRoleImage: string?,										-- The image that will be shown to the right of the player's name.
}

export type titlePresetsType = {
	leadDeveloper: titlePresetType,
	seniorDeveloper: titlePresetType,
	developer: titlePresetType,
	qaTester: titlePresetType,
	contributor: titlePresetType,
	
	supporter: titlePresetType,
	
	default: titlePresetType,
}

local titlePresets: titlePresetsType = {
	
	-- Group Titles --
	leadDeveloper = {
		requirementType = titleRequirements.requireSpecificGroupRank,
		requiredGroupRanks = {255},
		priority = math.huge,
		
		title = "Lead Developer",
		tagColor = Color3.fromRGB(255, 74, 86),
		
		strokeThickness = 1,
		strokeColor = Color3.fromRGB(83, 24, 28),
		fontType = "rbxassetid://12187361943",
		chatColor = Color3.fromRGB(255, 203, 210),
		
		overheadGui = true,
		overheadRoleImage = "rbxassetid://16001165874",
	},
	
	seniorDeveloper = {
		requirementType = titleRequirements.requireSpecificGroupRank,
		requiredGroupRanks = {254},
		priority = 9999,

		title = "Senior Developer",
		tagColor = Color3.fromRGB(3, 255, 150),

		strokeThickness = 1.5,
		strokeColor = Color3.fromRGB(1, 115, 68),
		fontType = "rbxassetid://12187361943",
		chatColor = Color3.fromRGB(189, 255, 222),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://16001166053",
	},

	developer = {
		requirementType = titleRequirements.requireSpecificGroupRank,
		requiredGroupRanks = {253},
		priority = 5000,

		title = "Developer",
		tagColor = Color3.fromRGB(46, 218, 20),

		strokeThickness = 1,
		strokeColor = Color3.fromRGB(18, 84, 8),
		fontType = "rbxassetid://12187361943",
		chatColor = Color3.fromRGB(101, 109, 176),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://16071026167",
	},

	qaTester = {
		requirementType = titleRequirements.requireSpecificGroupRank,
		requiredGroupRanks = {5},
		priority = 1000,

		title = "QA Tester",
		tagColor = Color3.fromRGB(224, 212, 255),

		strokeThickness = 0,
		strokeColor = Color3.fromRGB(229, 249, 255),
		fontType = "rbxassetid://1218760662",
		chatColor = Color3.fromRGB(217, 240, 255),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://0",
	},

	contributor = {
		requirementType = titleRequirements.requireSpecificGroupRank,
		requiredGroupRanks = {4},
		priority = 500,

		title = "Contributor",
		tagColor = Color3.fromRGB(255, 197, 252),

		strokeThickness = 0,
		strokeColor = Color3.fromRGB(229, 249, 255),
		fontType = "rbxassetid://1218760662",
		chatColor = Color3.fromRGB(255, 255, 255),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://14067540844",
	},
	
	donator = {
		requirementType = titleRequirements.requireAnyGamepass,
		requiredGamepasses = {19735869, 1317266210, 21220051, 21220124, 21220213, 1292936666},
		priority = 100,

		title = "Donator",
		tagColor = Color3.fromRGB(156, 176, 155),

		strokeThickness = 0,
		strokeColor = Color3.fromRGB(229, 249, 255),
		fontType = "rbxassetid://16658221428",
		chatColor = Color3.fromRGB(235, 255, 239),

		overheadGui = false,
		overheadRoleImage = "",
	},
	
	supporter = {
		requirementType = titleRequirements.requireAnyGamepass,
		requiredGamepasses = {1317266210, 21220051, 21220124, 21220213, 27800045, 1292936666, 1295498522},
		priority = 101,

		title = "Supporter",
		tagColor = Color3.fromRGB(130, 176, 121),

		strokeThickness = 0,
		strokeColor = Color3.fromRGB(229, 249, 255),
		fontType = "rbxassetid://16658221428",
		chatColor = Color3.fromRGB(210, 255, 211),

		overheadGui = true,
		overheadRoleImage = "",
	},
	
	majorSupporter = {
		requirementType = titleRequirements.requireAnyGamepass,
		requiredGamepasses = {21220124, 21220213, 27800045, 1295498522},
		priority = 102,

		title = "Major Supporter",
		tagColor = Color3.fromRGB(87, 176, 83),

		strokeThickness = 0,
		strokeColor = Color3.fromRGB(229, 249, 255),
		fontType = "rbxassetid://16658221428",
		chatColor = Color3.fromRGB(172, 255, 186),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://103315163536326",
	},
	
	topDonator = {
		requirementType = titleRequirements.requireAnyGamepass,
		requiredGamepasses = {27800045, 21220213, 1295498522},
		priority = 250,

		title = "Top Donator",
		tagColor = Color3.fromRGB(84, 255, 58),

		strokeThickness = .5,
		strokeColor = Color3.fromRGB(45, 132, 38),
		fontType = "rbxassetid://16658221428",
		chatColor = Color3.fromRGB(139, 255, 149),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://103315163536326",
	},
	
	earlySupporter = {
		requirementType = titleRequirements.requireAnyGamepass,
		requiredGamepasses = {20382403, 21778373},
		priority = 499,

		title = "Early Supporter",
		tagColor = Color3.fromRGB(255, 232, 60),

		strokeThickness = 1,
		strokeColor = Color3.fromRGB(132, 120, 33),
		fontType = "rbxassetid://12187369802",
		chatColor = Color3.fromRGB(255, 255, 130),

		overheadGui = true,
		overheadRoleImage = "rbxassetid://103315163536326",
	},
	
	-- Default Title --
	default = {
		requirementType = titleRequirements.none,
		priority = 0,

		title = "",
		tagColor = Color3.fromRGB(229, 249, 255),

		strokeThickness = 0,
		strokeColor = Color3.fromRGB(229, 249, 255),
		fontType = "rbxassetid://16658221428",
		chatColor = Color3.fromRGB(255, 255, 255),

		overheadGui = false,
		overheadRoleImage = nil,
	},
}

return titlePresets
