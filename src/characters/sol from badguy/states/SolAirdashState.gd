extends State

# settings
var dash_acceleration_time: int = 4 # time (in frames) to accelerate to max speed
var dash_speed: int = 20 # dash max speed
var dash_duration: int = 18 # dash total duration


var dash_friction: int = (dash_speed / dash_duration) / 2
var dash_acceleration: int = ceil(dash_speed / dash_acceleration_time)

# internal
var dash_direction: int

func ready() -> void:
	if dash_acceleration_time > dash_duration: dash_acceleration_time = dash_duration

func enter(input: Dictionary, last_state: State) -> void:
	super.enter(input, last_state)
	
	if (
	input.has('input_vector') and 
	input.get('input_vector').x != 0 and
	character.check_dash_input(input) and
	character.air_dash_counter < character.AIR_DASHES
	 ):
		# airdash happens
		
		dash_direction = input.get('input_vector').x
		
		if character.x_velocity * dash_direction < 0: character.x_velocity = 0 
		character.y_velocity = 0
		
		character.use_air_action()
		
	else:
		exit_into($"../Airborne")
		return

func tick(input: Dictionary) -> void:
	super.tick(input)

	
	if (
		current_frame <= dash_acceleration_time and
		character.x_velocity ** 2 < dash_speed ** 2
		):
			
		# if x_velocity < dash_speed, accounts for positive and negative
		character.x_velocity += dash_direction * dash_acceleration
	
	# max speed check
	# right now doesn't account for switching from negative to positive momentum
	# x_velocity > dash_speed, accounts for positive and negative
	if character.x_velocity ** 2 > dash_speed ** 2: character.x_velocity = dash_direction * dash_speed
		
		
		
	if current_frame >= dash_duration:
		# dash end
		# character.x_velocity = 0
		
		exit_into($"../Airborne")
		return

func exit() -> void:
	character.x_friction = 0

func save_state() -> Dictionary:
	var rollback_state := {}
	
	rollback_state['dash_direction'] = dash_direction
	
	return rollback_state

func load_state(rollback_state: Dictionary) -> void:
	dash_direction = rollback_state.get('dash_direction')
