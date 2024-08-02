extends Node
class_name StateMachine

# choose from editor
@export var initial_state : State

# settings
@export var debug : bool = false

# debug
@export var fsm_debug_label: RichTextLabel

# signals
signal state_changed(from: State, to: State)

# internal
var state: State
var player: Node2D
var character: Character

var current_frame: int
var last_state: State
var last_input: Dictionary

func _ready() -> void:
	state = initial_state
	last_state = initial_state
	
func init() -> void:
	_enter_state()
	
func change_to(new_state) -> void:
	# wrapper method
	if new_state == null:
		# not supposed to happen
		if debug: print('DEBUG: new_state is null on ' + character.name)
	elif not (new_state is State):
		new_state = get_node(new_state)
		
	state_changed.emit(state, new_state)
	last_state = state
	change_to_without_init(new_state)
	_enter_state()
	
func change_to_without_init(new_state) -> void:
	# used in rollback, to stop processing _enter() during rollbacks
	if new_state is State:
		state = new_state
	elif new_state == null:
		# not supposed to happen
		if debug: print('DEBUG: new_state is null on ' + character.name)
	else:
		state = get_node(new_state)
	
func _enter_state() -> void:
	# called from _ready and change_to()
	current_frame = 0
	
	if debug: print("DEBUG: Entering state: ", state.name)
	
	state.fsm = self

	state.player = player
	state.character = character
	state.debug = debug
	state.current_frame = current_frame
	
	state.enter(last_input, last_state)
	
func tick(input: Dictionary) -> void:
	# called from character.tick()
	last_input = input
	current_frame += 1
	
	if state:
		if fsm_debug_label: fsm_debug_label.text = state.name
		state.current_frame = current_frame
		state.tick(input)
	elif not state:
		# state is null
		if debug: print('DEBUG: state is null on ' + character.name)

func rollback_save_state() -> Dictionary:
	# called from character.save_state()
	var rollback_state := {}
	if state: rollback_state['character_state_path'] = state.get_path()
	
	if last_state: rollback_state['last_character_state_path'] = last_state.get_path()
	
	rollback_state['character_state_frame'] = current_frame
	if state.has_method('save_state'):
		rollback_state.merge(state.save_state())

	return rollback_state

func rollback_load_state(rollback_state: Dictionary) -> void:
	# called from character.load_state()
	var last_character_state = rollback_state.get('last_character_state_path')
	if last_character_state: last_state = get_node(last_character_state)
	
	current_frame = rollback_state.get('character_state_frame')
	state.current_frame = current_frame
	
	var character_state_path = rollback_state.get('character_state_path')
	if character_state_path: 
		var character_state = get_node(character_state_path)
		change_to_without_init(character_state)

	if state and state.has_method('load_state'):
		state.load_state(rollback_state)
