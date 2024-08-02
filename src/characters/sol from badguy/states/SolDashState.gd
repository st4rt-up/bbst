extends State

# settings
@export var dash_speed: int = 50
@export var dash_timer: int = 13
@export var dash_friction: int = dash_speed / dash_timer

# internal
var dash_direction: int
var counter: int = 0

func enter(input: Dictionary, last_state: State) -> void:
	super.enter(input, last_state)
	
	var dash_input: bool = (
		(input.has('dash_held') and 
		input.get('dash_held') > 0 and
		input.get('dash_held') <= 5) 
		or character.check_motion_input([6, 6], input.get('direction_array'), 10)
		or character.check_motion_input([4, 4], input.get('direction_array'), 10))


	if dash_input:
		counter = 0
		dash_direction = input.get('input_vector').x
		character.x_velocity = dash_direction * dash_speed
		character.x_friction = dash_direction * dash_friction
		
	else:
		exit_into($"../Idle")
		return

func tick(input: Dictionary) -> void:
	super.tick(input)
	
	if not character.grounded: 
		exit_into($"../Airborne")
		return
	
	counter += 1
	
	if input.get('up_held'):
		# dash jump
		if counter < dash_timer / 2:
			# good dash jump
			character.x_velocity = (dash_speed / 2) * dash_direction
		else:
			character.x_velocity = 10 * dash_direction
		
		character.y_velocity = -1 * character.JUMP_VELOCITY * sin(deg_to_rad(character.JUMP_ANGLE))
		exit_into($"../Airborne")
		return
	
	if false:
		# transition into run here
		pass
	
	if counter >= dash_timer:
		# dash end
		character.x_velocity = 0
		character.y_velocity = 0
		exit_into($"../Idle")
		return

func exit() -> void:
	counter = 0
	dash_direction = 0
	
	character.x_friction = 0

	
func save_state() -> Dictionary:
	var rollback_state := {}
	
	rollback_state['dash_direction'] = dash_direction
	rollback_state['dash_counter'] = counter
	
	return rollback_state

func load_state(rollback_state: Dictionary) -> void:
	counter = rollback_state.get('dash_counter')
	dash_direction = rollback_state.get('dash_direction')
