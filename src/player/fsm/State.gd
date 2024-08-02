extends Node
class_name State

var fsm: StateMachine
var character: Character
var player: Node2D

@export var hurtbox: Hurtbox

var debug: bool
var current_frame: int = 0

func _ready() -> void:
	return

func enter(_input: Dictionary, _last_state: State) -> void:
	if hurtbox: hurtbox.enable()

func tick(_input: Dictionary) -> void:
	return

func exit() -> void:
	# code that runs on state exit
	if hurtbox: hurtbox.disable()

func exit_into(next_state) -> void:
	# wrapper method, for consistent naming with enter()
	# exit into next_state, do not override
	exit()
	fsm.change_to(next_state)
