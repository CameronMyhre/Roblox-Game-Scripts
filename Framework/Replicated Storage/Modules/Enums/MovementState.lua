export type movementState = number

export type movementStates = {
	walking: movementState,
	crouching: movementState,
	running: movementState,
}

local module: movementStates = {
	walking = 0,
	crouching = 1,
	running = 2
}

return module
