export type titleRequirementType = number

export type titleRequirementTypes = {
	requireSpecificGroupRank: titleRequirementType,
	requireGroupRankOrHigher: titleRequirementType,

	requireAnyBadge: titleRequirementType,
	requireAllBadges: titleRequirementType,

	requireAnyGamepass: titleRequirementType,
	requireAllGamepasses: titleRequirementType,

	none: titleRequirementType
}

local titleRequirements: titleRequirementTypes = {
	
	requireSpecificGroupRank = 0,
	requireGroupRankOrHigher = 1,
	
	requireAnyBadge = 2,
	requireAllBadges = 3,
	
	requireAnyGamepass = 4,
	requireAllGamepasses = 5,
	
	none = 6
}

return titleRequirements