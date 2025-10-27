-- Useful types
export type DroneState = number

export type DroneActionStates = {
	idle: DroneState,
	wandering: DroneState,
	searching: DroneState,
	chasing: DroneState,
	attacking: DroneState,
	dead: DroneState
}

local droneActionState: DroneActionStates = {
	idle = 0,
	wandering = 1,
	searching = 2,
	chasing = 3,
	attacking = 4,
	dead = 999
}

return droneActionState