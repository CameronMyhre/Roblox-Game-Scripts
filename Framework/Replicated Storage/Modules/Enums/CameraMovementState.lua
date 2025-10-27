export type playerMovementStates = {
	rotating: number,
	moving: number,
}

local playertMovementStates: playerMovementStates = {
	rotating = 0,
	moving = 1,
}

return playertMovementStates
