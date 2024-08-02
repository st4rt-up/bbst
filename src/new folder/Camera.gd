extends Camera2D

@onready var SERVER_PLAYER := $"../ServerPlayer"
@onready var CLIENT_PLAYER := $"../ClientPlayer"

@onready var label := $CameraLabel

func _network_process(input: Dictionary) -> void:
	# virtual method, from rollback addon
	# this is the same as _physics_process, but compatible with rollback
	# executed every tick 
	position.x = (SERVER_PLAYER.position.x + CLIENT_PLAYER.position.x) / 2
	position.y = (SERVER_PLAYER.position.y + CLIENT_PLAYER.position.y) / 2	
	
	var distance = max(SERVER_PLAYER.position.x, CLIENT_PLAYER.position.x) - min(SERVER_PLAYER.position.x, CLIENT_PLAYER.position.x)
	
	var z = clamp(1200 / distance, 1.1, 1.4)
	zoom = Vector2(z, z)
	
	position.y -= 40 * z
	label.text = str(z)
	return

func _save_state() -> Dictionary:
	# virtual method used for rollback addon
	var rollback_state := {
		'position_x' = position.x,
		'position_y' = position.y,
	}
	
	return rollback_state

func _load_state(rollback_state: Dictionary) -> void:
	position.x = rollback_state['position_x']
	position.y = rollback_state['position_y']
