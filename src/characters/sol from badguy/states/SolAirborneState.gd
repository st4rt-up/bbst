extends State

# settings
var ground_level: int = 400

func enter(input: Dictionary, last_state: State) -> void:
	super.enter(input, last_state)
	
	character.airborne = true
	character.grounded = false


func tick(input: Dictionary) -> void:
	super.tick(input)
	
	if character.y_position <= character.ground_level:
		# character is above the ground
		
		# air dash
		if (
			input.has('input_vector') and
			input.get('input_vector').x != 0 and
			character.check_dash_input(input) and
			character.air_dash_counter < character.AIR_DASHES
		): 
			
			var rising_height_check = character.y_velocity < 0 and character.y_position < ground_level - 110
			var falling_height_check = character.y_velocity >= 0 and character.y_position < ground_level - 40
			
			if rising_height_check or falling_height_check:
				# minimum height requirement
				exit_into($"../Airdash")
				return
			
		if character.y_position + character.y_velocity >= ground_level:
			# gravity would push below floor
			character.y_position = ground_level
			character.y_velocity = 0
			character.airborne = false
			character.grounded = true
			exit_into($"../Idle")
			return
		
		# double jump check
		if (
			input.has('input_vector') and
			input.get('input_vector').y < 0 and
			input.get('up_held') < 5 and
			character.double_jump_counter < character.DOUBLE_JUMPS
		):
			var rising_height_check = character.y_velocity < 0 and character.y_position < ground_level - 110
			var falling_height_check = character.y_velocity >= 0
			
			if rising_height_check or falling_height_check:
				# code can be changed to support double jumps having different properties than normal jump
				var jump_direction = input.get('input_vector').x
				
				character.x_velocity = jump_direction * character.JUMP_VELOCITY * cos(deg_to_rad(character.JUMP_ANGLE))
				character.y_velocity = -1 * character.JUMP_VELOCITY * sin(deg_to_rad(character.JUMP_ANGLE))
				character.use_air_action()
		
		# airborne state logic
		if character.y_velocity + character.gravity >= character.terminal_velocity:
			character.y_velocity = character.terminal_velocity
		else:
			character.y_velocity += character.gravity
			
	else:
		# is currently below floor
		character.y_position = 400
		character.y_velocity = 0
		character.airborne = false
		character.grounded = true
		exit_into($"../Idle")
		return	
