extends Node2D
class_name Player
# handles input, saving state and loading state

# passes input to character scenes
# character scenes are responsible for character logic
# also delegates most things down to character, in save_state, load_state and network_process

# choose from editor
@export var character: Character

# internal
var other_player: Player
var other_character: Character

var input_prefix := "p1_"

# relative
# most recent input is index 0
var direction_buffer_array: Array[Vector2i] = [Vector2i(0,0)]

# absolute
# most recent input is index 0
# still uses numpad notation, does not flip
var direction_buffer_array_absolute: Array[Vector2i] = [Vector2i(0,0)]

# above arrays are added into input dict in _network_process so we can use static typing
var input_buffer := {	
	'input_vector' = Vector2i.ZERO,
	
	"left_held" = 0,
	"right_held" = 0,
	"up_held" = 0,
	"down_held" = 0,
	
	"dash_held" = 0,
	
	"action_1_held" = 0,
	"action_2_held" = 0,
	"action_3_held" = 0,
	"action_4_held" = 0,
	"action_5_held" = 0,	
}

enum PlayerInput {
	INPUT_VECTOR,
	BUTTONS,
	EXTRAS
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

enum Facing {
	LEFT = -1,
	RIGHT = 1,
}

func _get_local_input() -> Dictionary:	
	# virtual method, used for rollback addon
	# wrapper
	return get_input()

func get_input() -> Dictionary:
	var input := {}

	# direction is processed this way to get rid of floats and for SOCD cleaning
	var input_vector := Vector2i.ZERO
	if Input.is_action_pressed(input_prefix + "left"): input_vector.x -= 1
	if Input.is_action_pressed(input_prefix + "right"): input_vector.x += 1
	if Input.is_action_pressed(input_prefix + "up"): input_vector.y -= 1
	if Input.is_action_pressed(input_prefix + "down"): input_vector.y += 1
	
	if input_vector != Vector2i.ZERO: input["input_vector"] = input_vector
	
	if Input.is_action_pressed(input_prefix + "dash"): input["dash"] = true
	
	# actions
	if Input.is_action_pressed(input_prefix + "action_1"): input["action_1"] = true
	if Input.is_action_pressed(input_prefix + "action_2"): input["action_2"] = true
	if Input.is_action_pressed(input_prefix + "action_3"): input["action_3"] = true
	if Input.is_action_pressed(input_prefix + "action_4"): input["action_4"] = true
	if Input.is_action_pressed(input_prefix + "action_5"): input["action_5"] = true
	
	return input

func _predict_remote_input(previous_input: Dictionary, _ticks_since_real_input: int) -> Dictionary:
	# virtual method used for rollback addon
	# right now it is doing nothing but assuming buttons are being held down
	
	var predicted_input = previous_input.duplicate()
	return predicted_input

func _network_process(input: Dictionary) -> void:
	# virtual method, from rollback addon
	# this is the same as _physics_process, but compatible with rollback
	# executed every tick 

	# processes input then delegates further processing to character 

	# -= INPUT PROCESSING
	var processed_input := {}
	
	var facing_direction: int = Facing.RIGHT 
	if character: facing_direction = character.facing_direction

	var input_vector: Vector2i = input.get('input_vector', Vector2i.ZERO)
	input_buffer['input_vector'] = input_vector
	
	# directions processing
	# used for charge
	# Vector2i is used as a tuple with x being direction and y being frames held
	if input_vector.x < 0: input_buffer['left_held'] += 1 
	else: input_buffer['left_held'] = 0
	
	if input_vector.x > 0: 	input_buffer['right_held'] += 1	
	else: input_buffer['right_held'] = 0
	
	if input_vector.y < 0: input_buffer['up_held'] += 1
	else: input_buffer['up_held'] = 0
	
	if input_vector.y > 0: input_buffer['down_held'] += 1
	else: input_buffer['down_held'] = 0

	var input_vector_numpad: int = 5

	# store direction in absolute buffer, compressed
	input_vector_numpad = vec_to_numpad(input_vector)
	if direction_buffer_array[0].x != input_vector_numpad:
		direction_buffer_array.insert(0, Vector2i(input_vector_numpad, 1))
	else: direction_buffer_array[0].y += 1
	
	# store direction in relative buffer, compressed
	input_vector_numpad = vec_to_numpad(input_vector, facing_direction)
	if direction_buffer_array_absolute[0].x != input_vector_numpad:
		direction_buffer_array_absolute.insert(0, Vector2i(input_vector_numpad, 1))
	else: direction_buffer_array_absolute[0].y += 1

	
	# clear old inputs from buffer
	const BUFFER_MAX_SIZE:int  = 15

	if direction_buffer_array.size() > BUFFER_MAX_SIZE: 
		direction_buffer_array.pop_back()
	if direction_buffer_array_absolute.size() > BUFFER_MAX_SIZE: 
		direction_buffer_array_absolute.pop_back()

	# buttons processing
	# dash
	if input.get('dash'): 
		input_buffer["dash_held"] += 1
	else: input_buffer["dash_held"] = 0
	
	# actions
	# held frames are kept track of so different motions can have different leniency
	if input.get("action_1"): input_buffer["action_1_held"] += 1
	else: input_buffer["action_1_held"] = 0
	
	if input.get("action_2"): input_buffer["action_2_held"] += 1
	else: input_buffer["action_2_held"] = 0
		
	if input.get("action_3"): input_buffer["action_3_held"] += 1
	else: input_buffer["action_3_held"] = 0
	
	if input.get("action_4"): input_buffer["action_4_held"] += 1
	else: input_buffer["action_4_held"] = 0
		
	if input.get("action_5"): input_buffer["action_5_held"] += 1
	else: input_buffer["action_5_held"] = 0
	
	processed_input.merge(input_buffer.duplicate())
	processed_input['direction_array'] = direction_buffer_array.duplicate()
	processed_input['direction_array_absolute'] = direction_buffer_array_absolute.duplicate()

	# -= CHARACTER CODE

	if character:
		# this cleans up code in character and below 
		character.x_position = int(position.x)
		character.y_position = int(position.y)
		
		character.tick(processed_input)
		
		position.x = character.x_position
		position.y = character.y_position
	
	else: print('ERROR: Character not set on Player node ' + self.name + '!')

func _save_state() -> Dictionary:
	# virtual method used for rollback addon
	var rollback_state := {
		'player_position_x' = position.x,
		'player_position_y' = position.y,
		
		'buffer_array' = direction_buffer_array.duplicate(),
		'buffer_array_absolute' = direction_buffer_array_absolute.duplicate(),
		
		'buffer_input_vector' = input_buffer.get('input_vector', Vector2i.ZERO),
		
		'buffer_left_held' = input_buffer.get('left_held', 0),
		'buffer_right_held' = input_buffer.get('right_held', 0),
		'buffer_up_held' = input_buffer.get('up_held', 0),
		'buffer_down_held' = input_buffer.get('down_held', 0),
		
		'buffer_dash_held' = input_buffer.get('dash_held', 0),
		
		'buffer_action_1_held' = input_buffer.get('action_1_held'),
		'buffer_action_2_held' = input_buffer.get('action_2_held'),
		'buffer_action_3_held' = input_buffer.get('action_3_held'),
		'buffer_action_4_held' = input_buffer.get('action_4_held'),
		'buffer_action_5_held' = input_buffer.get('action_5_held'),
	}
	
	if character:
		var character_state = character.rollback_save_state().duplicate()
		rollback_state.merge(character_state)
	
	return rollback_state

func _load_state(rollback_state: Dictionary) -> void:
	# virtual method used for rollback addon
	position.x = rollback_state['player_position_x']
	position.y = rollback_state['player_position_y']
	
	direction_buffer_array = rollback_state.get('buffer_array').duplicate()
	direction_buffer_array_absolute = rollback_state.get('buffer_array_absolute').duplicate()
	
	input_buffer['input_vector'] = rollback_state.get('buffer_input_vector', Vector2i.ZERO)
	
	input_buffer['left_held'] = rollback_state.get('buffer_left_held')
	input_buffer['right_held'] = rollback_state.get('buffer_right_held')
	input_buffer['up_held'] = rollback_state.get('buffer_up_held')
	input_buffer['down_held'] = rollback_state.get('buffer_down_held')
	
	input_buffer['dash_held'] = rollback_state.get('buffer_dash_held')
	
	input_buffer['action_1_held'] = rollback_state.get('buffer_action_1_held')
	input_buffer['action_2_held'] = rollback_state.get('buffer_action_2_held')
	input_buffer['action_3_held'] = rollback_state.get('buffer_action_3_held')
	input_buffer['action_4_held'] = rollback_state.get('buffer_action_4_held')
	input_buffer['action_5_held'] = rollback_state.get('buffer_action_5_held')
	
	if character: character.rollback_load_state(rollback_state)

func vec_to_numpad(vec_direction: Vector2i, flipped: bool = false) -> int:
	if flipped: vec_direction.x = -vec_direction.x
	match vec_direction:
		Vector2i(-1,1): return Numpad.DOWN_BACK
		Vector2i(0,1): return Numpad.DOWN
		Vector2i(1,1): return Numpad.DOWN_FORWARD
		Vector2i(-1,0): return Numpad.BACK
		Vector2i(0,0): return Numpad.NEUTRAL
		Vector2i(1,0): return Numpad.FORWARD
		Vector2i(-1,-1): return Numpad.UP_BACK
		Vector2i(0,-1): return Numpad.UP
		Vector2i(1,-1): return Numpad.UP_FORWARD
	return 0
	
func numpad_to_vec(numpad_direction: int, flipped: bool = false) -> Vector2i:
	var vec_direction = Vector2i.ZERO
	match numpad_direction:
		Numpad.DOWN_BACK: vec_direction = Vector2i(-1,1)
		Numpad.DOWN: vec_direction = Vector2i(0,1)
		Numpad.DOWN_FORWARD: vec_direction = Vector2i(1,1)
		Numpad.BACK: vec_direction = Vector2i(-1,0)
		Numpad.NEUTRAL: vec_direction = Vector2i(0,0)
		Numpad.FORWARD: vec_direction = Vector2i(1,0)
		Numpad.UP_BACK: vec_direction = Vector2i(-1,-1)
		Numpad.UP: vec_direction = Vector2i(0,-1)
		Numpad.UP_FORWARD: vec_direction = Vector2i(1,-1)

	if flipped: vec_direction.x = -vec_direction.x
	return vec_direction
