extends State

func enter(input: Dictionary, last_state: State) -> void:
	super.enter(input, last_state)
	character.x_velocity = 0
	
	if character.y_position < character.ground_level:
		# character off the ground
		# forced into idle
		exit_into($"../Airborne")
		return
	
	if input.get('left_held') or input.get('right_held'):
		exit_into($"../Walk")
		return
		
	# character on the ground
	# should happen under normal circumstances
	character.reset_air_actions()

func tick(input: Dictionary) -> void:
	super.tick(input)
	
	if character.y_position > 400:
		# idle grounded
		character.y_position = 400
		character.grounded = true
		character.airborne = false
		
	elif character.y_position > character.ground_level:
		# idle in mid-air
		exit_into($"../Airborne")
		return
		
	var input_vector = input.get('input_vector')
	if input_vector != Vector2i.ZERO:

		# dash check
		var dash_input: bool = character.check_dash_input(input)
		
		if dash_input:
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
		
		if input.get('left_held') or input.get('right_held'):
			exit_into($"../Walk")
			return
