extends Node
class_name Character

# takes input from a player parent class, which is passed through:
# player._network_process() -> state_machine.tick() -> [current state].tick()

# responsible for sprites, moves, sounds and other misc character logic

# expected that subclasses override save_state() and load_state()

# choose in editor
@export var state_machine : StateMachine
@export var sprite : AnimatedSprite2D

# settings
var debug: bool = false

# internal
var player: Node2D
var air_dash_counter: int = 0
var double_jump_counter: int = 0

# hit properties
var counter_hit: bool = false

var airborne: bool = false
var grounded: bool = false

var strike_invuln: bool = false
var projectile_invuln: bool = false
var throw_invuln: bool = false

var armoured: bool = false
var guard_point: bool = false

# movement properties
var AIR_DASHES: int = 2
var DOUBLE_JUMPS: int = 1

var JUMP_VELOCITY: int = 22
var JUMP_ANGLE: int = 63

var GROUND_FRICTION: float
var AIR_FRICTION: float

var facing_direction: Facing

enum Facing {
	LEFT = -1,
	RIGHT = 1,
}

enum Numpad {
	DOWN_BACK = 1,
	DOWN = 2,
	DOWN_FORWARD = 3,
	BACK = 4,
	NEUTRAL = 5,
	FORWARD =  6,
	UP_BACK = 7,
	UP = 8,
	UP_FORWARD = 9,

	DOWN_LEFT = 1,
	DOWN_RIGHT = 3,
	LEFT = 4,
	RIGHT = 6,
	UP_LEFT = 7,
	UP_RIGHT = 9,
	
	ANY_UP = 10,
	ANY_DOWN = 11,
	ANY_BACK = 12,
	ANY_FORWARD = 13,

	ANY_LEFT = 14,
	ANY_RIGHT = 15,
}

# used for "physics" calcs 
var x_position: int
var y_position: int

var x_velocity: int = 0
var y_velocity: int = 0

var x_friction: int = 0
var y_friction: int = 0

var gravity: int = 1

func _ready() -> void:
	# called when this node is fully loaded
	player = get_parent()
	
	init()
	
	if state_machine:
		state_machine.player = player
		state_machine.character = self
		state_machine.init()

func init() -> void:
	return

func tick(input) -> void:
	# called from player._network_process()
	state_machine.tick(input)
	
	# we can change this code if colliding with the other player
	x_velocity -= x_friction
	y_velocity -= y_friction
	
	x_position += x_velocity
	y_position += y_velocity

func rollback_save_state() -> Dictionary:
	# called from player._save_state()
	# call this with super.save_state() in subclasses
	
	# every single instance variable has to be saved in state
	var rollback_state := {
		'airborne' = airborne,
		'grounded' = grounded,
		
		'strike_invuln' = strike_invuln,
		'projectile_invuln' = projectile_invuln,
		'throw_invuln' = throw_invuln,
		
		'armoured' = armoured,
		'guard_point' = guard_point,
		
		'character_x_position' = x_position,
		'character_y_position' = y_position,
		
		'x_velocity' = x_velocity,
		'y_velocity' = y_velocity,
		
		'x_friction' = x_friction,
		'y_friction' = y_friction,
		
		'gravity' = gravity,
		
		'air_dash_counter' = air_dash_counter,
		'double_jump_counter' = double_jump_counter,

		'air_dashes' = AIR_DASHES,
		'double_jumps' = DOUBLE_JUMPS,

		'jump_velocity' = JUMP_VELOCITY,
		'jump_angle' = JUMP_ANGLE,
	}
	
	#if sprite:
		#rollback_state['sprite_animation'] = sprite.animation
		#rollback_state['sprite_frame'] = sprite.frame
	
	return rollback_state

func rollback_load_state(rollback_state: Dictionary) -> void:
	# called from player._load_state()
	# if debug: print('load state not implemented for ' + self.name + ', using default')
	
	if state_machine:
		state_machine.rollback_load_state(rollback_state)
		
	#if sprite:
		#sprite.animation = rollback_state.get('sprite_animation')
		#sprite.frame = rollback_state.get('sprite_frame')
	
	# every instance variable in save_state() needs to be loaded here from the dictionary
	airborne = rollback_state.get('airborne')
	grounded = rollback_state.get('grounded')
	
	strike_invuln = rollback_state.get('strike_invuln')
	projectile_invuln = rollback_state.get('projectile_invuln')
	throw_invuln = rollback_state.get('throw_invuln')
	
	armoured = rollback_state.get('armoured')
	guard_point = rollback_state.get('guard_point')
	
	x_position = rollback_state.get('character_x_position')
	y_position = rollback_state.get('character_y_position')
	
	x_velocity = rollback_state.get('x_velocity')
	y_velocity = rollback_state.get('y_velocity')
		
	x_friction = rollback_state.get('x_friction')
	y_friction = rollback_state.get('y_friction')
		
	gravity = rollback_state.get('gravity')
		
	air_dash_counter = rollback_state.get('air_dash_counter')
	double_jump_counter = rollback_state.get('double_jump_counter')

	AIR_DASHES = rollback_state.get('air_dashes')
	DOUBLE_JUMPS = rollback_state.get('double_jumps')
	JUMP_VELOCITY = rollback_state.get('jump_velocity')
	JUMP_ANGLE = rollback_state.get('jump_angle')

func use_air_action() -> void:
	air_dash_counter += 1
	double_jump_counter += 1
	
func reset_air_actions() -> void:
	air_dash_counter = 0
	double_jump_counter = 0

func check_motion_input(
	motion_input: Array[Numpad], 
	buffer: Array[Vector2i],
	window: int, 
	buffer_size: int= 10) -> bool:

	if buffer.size() < motion_input.size(): return false

	# rename "recent"
	var recent: Array[Vector2i] = buffer.slice(0, buffer_size)

	var counter: int = motion_input.size()
	var total_frames: int = 0

	for i in recent.size() - 1:
		
		var check_direction: Numpad = motion_input[counter - 1]
		var buffer_direction: Numpad = recent[i].x
		var frames: int = recent[i].y

		if counter != 0: total_frames += frames

		if (
			check_direction <= 9 and
			check_direction == buffer_direction and 
			counter > 0 and 
			total_frames <= window
			): 
				counter -= 1

		if (
			check_direction >= 10 and
			counter > 0 and 
			total_frames <= window
			): 
			match check_direction:
				Numpad.ANY_UP: 
					if buffer_direction == 7 or buffer_direction == 8 or buffer_direction == 9: counter -= 1 
				Numpad.ANY_DOWN:
					if buffer_direction == 1 or buffer_direction == 2 or buffer_direction == 3: counter -= 1
				Numpad.ANY_BACK:
					if buffer_direction == 1 or buffer_direction == 4 or buffer_direction == 7: counter -= 1
				Numpad.ANY_FORWARD:
					if buffer_direction == 3 or buffer_direction == 6 or buffer_direction == 9: counter -= 1

	
	if counter == 0 and total_frames <= window: 
		return true
	return false

func check_dash_input(input: Dictionary) -> bool:
	var dash_input: bool = (
		(
		input.has('dash_held') and 
		input.get('dash_held') > 0 and
		input.get('dash_held') <= 5
		) 
		or check_motion_input([13, 5, 6], input.get('direction_array'), 10)
		or check_motion_input([12, 5, 4], input.get('direction_array'), 10) 
		)
		
	return dash_input
	
func check_charge_input(motion_input: Array[int], buffer: Array[Vector2i], charge_time: int) -> bool:
	return false

func face_left() -> void:
	return
	
func face_right() -> void:
	return
