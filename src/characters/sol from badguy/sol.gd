extends Character
# example character scene, responsible for most game logic (not input)

@export var input_label: RichTextLabel

var terminal_velocity: int = 30
var ground_level: int = 400

func init() -> void:
	# set character stats here
	return

func rollback_save_state() -> Dictionary:
	# run from player._save_state()
	var rollback_state := {
		'ground_level' = ground_level
	}
	
	if state_machine:
		rollback_state.merge(state_machine.rollback_save_state())
	
	rollback_state.merge(super.rollback_save_state().duplicate())
	return rollback_state

func rollback_load_state(rollback_state: Dictionary) -> void:
	# run from player._save_state()
	super.rollback_load_state(rollback_state)
	
	ground_level = rollback_state.get('ground_level')
