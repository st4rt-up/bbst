extends State

# settings
@export var move_speed : int = 8

func enter(input: Dictionary, last_state: State) -> void:
	if character.grounded or character.y_position > 400:
		# idle grounded
		character.y_position = 400
		character.grounded = true
		character.airborne = false
		
		character.air_dash_counter = 0
		character.double_jump_counter = 0

func tick(input: Dictionary) -> void:
	super.tick(input)
	
	if not character.grounded: 
		exit_into($"../Airborne")
		return
	
	var input_vector = input.get('input_vector')
	
	if input_vector != Vector2i.ZERO:
		
		if character.check_dash_input(input):
			exit_into($"../Dash")
			return		
		
		if input.get('up_held'):
			
			# regular jump
			character.y_velocity = -1 * character.JUMP_VELOCITY * sin(deg_to_rad(character.JUMP_ANGLE))
			character.x_velocity = input_vector.x * character.JUMP_VELOCITY * cos(deg_to_rad(character.JUMP_ANGLE))
			
			# super jump (down, then up)
			if character.check_motion_input([11, 10], input.get('direction_array'), 9):
				character.double_jump_counter = character.DOUBLE_JUMPS
				character.y_velocity *= 1.5

			exit_into($"../Airborne")
			return
		
		character.x_velocity = input_vector.x * move_speed

	else:
		exit_into($"../Idle")
		return
