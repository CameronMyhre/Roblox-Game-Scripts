-- Animations --
local animations = script:WaitForChild("Animations")
local crouchingAnims = animations:WaitForChild("Crawling")
local walkingAnims = animations:WaitForChild("Walking")
local runningAnims = animations:WaitForChild("Sprinting")

export type StateSettings = {
	stats: {
		walkSpeed: number,
		jumpPower: number
	},
	animations: {
		walkinAnim: any, -- Uses any to accomadate loaded and unlaoded animations.
		idleAnim: any,	-- Looped
		transitionInAnim: any?,
		transitionOutAnim: any?
	},
	cameraSettings: {
		fov: number,
		offset: Vector3
	},
	staminaCostPerSecond: number,
	idleRegen: number,
}

export type MovementModePreset = {
	crouching: StateSettings,
	walking: StateSettings,
	running: StateSettings,
	panic: StateSettings,
}

export type MovementModeManager = {
	default: MovementModePreset
}

local movementModes: MovementModeManager = {
	default = {
		crouching = {
			stats = {
				walkSpeed = 10,
				jumpPower = 30
			},
			animations = {
				walkinAnim = crouchingAnims:WaitForChild("Walking"), -- Uses any to accomadate loaded and unlaoded animations.
				idleAnim = crouchingAnims:WaitForChild("Idle"),
				transitionInAnim = crouchingAnims:WaitForChild("Transition- To"),
				transitionOutAnim = crouchingAnims:WaitForChild("Transition - From")
			},
			cameraSettings = {
				fov = 55,
				offset = Vector3.new(0, -1.25, 0)
			},
			staminaCostPerSecond = -40, -- Per second
			idleRegen = -39
		},
		walking = {
			stats = {
				walkSpeed = 16,
				jumpPower = 50
			},
			animations = {
				walkinAnim = walkingAnims:WaitForChild("Walking"),
				idleAnim = walkingAnims:WaitForChild("Idle"),
			},
			cameraSettings = {
				fov = 70,
				offset = Vector3.new(0, 0, 0)
			},
			staminaCostPerSecond = -30,
			idleRegen = -29
		},
		running = {
			stats = {
				walkSpeed = 26,
				jumpPower = 40
			},
			animations = {
				walkinAnim = runningAnims:WaitForChild("Walking"), 
				idleAnim = runningAnims:WaitForChild("Idle"),
			},
			cameraSettings = {
				fov = 90,
				offset = Vector3.new(0, 0, 0)
			},
			staminaCostPerSecond = 25,
			idleRegen = -29
		},
		panic = {
			stats = {
				walkSpeed = 30,
				jumpPower = 50
			},
			animations = {
				walkinAnim = runningAnims:WaitForChild("Walking"), 
				idleAnim = runningAnims:WaitForChild("Idle"),
			},
			cameraSettings = {
				fov = 110,
				offset = Vector3.new(0, 0, 0)
			},
			staminaCostPerSecond = 30,
			idleRegen = 0
		}
	}
}

return movementModes
