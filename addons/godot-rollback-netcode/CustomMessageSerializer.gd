extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

# WHY IS THIS HARDCODED
const input_path_mapping := {
	'/root/main/Game/ServerPlayer': 1,
	'/root/main/Game/ClientPlayer': 2,
}

var input_path_mapping_reverse := {}

const HeaderFlags = {
	HAS_INPUT_VECTOR = 0b0000000000000001,
	
	DASH = 0b0000010000000000,
	
	ACTION_1 = 0b0000000000100000,
	ACTION_2 = 0b0000000001000000,
	ACTION_3 = 0b0000000010000000,
	ACTION_4 = 0b0000000100000000,
	ACTION_5 = 0b0000001000000000,
}

func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(32)
	
	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])
		
		var header := 0
		
		# write header flags
		var input = all_input[path]
		if input.has('input_vector'): header |= HeaderFlags.HAS_INPUT_VECTOR
		
		if input.has('dash'): header |= HeaderFlags.DASH
		
		if input.has('action_1'): header |= HeaderFlags.ACTION_1
		if input.has('action_2'): header |= HeaderFlags.ACTION_2
		if input.has('action_3'): header |= HeaderFlags.ACTION_3
		if input.has('action_4'): header |= HeaderFlags.ACTION_4
		if input.has('action_5'): header |= HeaderFlags.ACTION_5
		
		# write 8 bit header to buffer
		buffer.put_u16(header)
		
		# write input direction to buffer
		if input.has('input_vector'):
			var input_vector: Vector2i = input['input_vector']
			buffer.put_8(input_vector.x)
			buffer.put_8(input_vector.y)
		
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input := {}
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	if input_count == 0:
		return all_input
		
	var path = input_path_mapping_reverse[buffer.get_u8()]
	var input := {}
	
	# check header flags
	var header = buffer.get_u16()
	if header & HeaderFlags.HAS_INPUT_VECTOR:
		input['input_vector'] = Vector2i(buffer.get_8(), buffer.get_8())
	
	if header & HeaderFlags.DASH: input['dash'] = true

	if header & HeaderFlags.ACTION_1: input['action_1'] = true
	if header & HeaderFlags.ACTION_2: input['action_2'] = true
	if header & HeaderFlags.ACTION_3: input['action_3'] = true
	if header & HeaderFlags.ACTION_4: input['action_4'] = true
	if header & HeaderFlags.ACTION_5: input['action_5'] = true
		
	all_input[path] = input
	
	# print("recieved input:" + str(input))
	return all_input
