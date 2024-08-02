extends Area2D
class_name Hurtbox

const HURTBOX_COLOUR := Color8(49, 163, 249, 128)

var is_enabled: bool = false

var player: Player
var character: Character

var hurtbox_owner: Player

func _ready() -> void:
	disable()

func _init() -> void: return

func tick(_input: Dictionary) -> void: return

func enable() -> void:
	is_enabled = true
	set_monitorable(true)
	set_monitoring(true)
	
	for child in get_children():
		if child is CollisionShape2D:
			child.set_disabled(false)
			child.visible = true

func disable() -> void:
	is_enabled = false
	set_monitorable(false)
	set_monitoring(false)
	
	for child in get_children():
		if child is CollisionShape2D:
			child.set_disabled(true)
			child.visible = false

func is_active() -> bool:
	return is_enabled
	
func get_hit(attack : Hitbox) -> void:
	return
