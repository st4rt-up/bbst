extends Node2D

# ui nodes, temp
@onready var connection_panel = $ui/ConnectionPanel
@onready var host_field = $ui/ConnectionPanel/GridContainer/HostField
@onready var port_field = $ui/ConnectionPanel/GridContainer/PortField
@onready var message_label = $ui/MessageLabel
@onready var sync_lost_label = $ui/SyncLostLabel

# functional ... ? may move later
@onready var game = $Game

@onready var server_player = $Game/ServerPlayer
@onready var client_player = $Game/ClientPlayer

# settings
var logging_enabled: bool = false
var LOG_FILE_DIRECTORY = "user://detailed_logs"

func _ready() -> void:
	# functional
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	SyncManager.sync_started.connect(_on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(_on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(_on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(_on_SyncManager_sync_error)

func _on_server_button_pressed():
	# functional
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text), 1)
	multiplayer.multiplayer_peer = peer
	
	# ui for testing
	connection_panel.visible = false
	message_label.text = "listening"

func _on_client_button_pressed():
	# functional
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	
	# ui for testing
	connection_panel.visible = false
	message_label.text = "connecting..."
	
func _on_network_peer_connected(peer_id: int):
	# ui for testing
	message_label.text = "connected!"
	
	# functional
	SyncManager.add_peer(peer_id)
	
	# set control of node depending on if server or client
	server_player.set_multiplayer_authority(1)
	if multiplayer.is_server():
		client_player.set_multiplayer_authority(peer_id)
	else:
		client_player.set_multiplayer_authority(multiplayer.get_unique_id())
	
	# wait to ping
	if multiplayer.is_server():
		message_label.text = "starting..." # ui for testing
		
		# functional
		# ping wait time was chosen arbitrarily
		const PING_WAIT_TIME = 2.0
		await get_tree().create_timer(PING_WAIT_TIME).timeout
		SyncManager.start()
	
func _on_network_peer_disconnected(peer_id: int):
	# ui for testing
	message_label.text = "disconnected!"
	
	# functional
	SyncManager.remove_peer(peer_id)
	
func _on_server_disconnected() -> void:
	# functional
	_on_network_peer_disconnected(1)

func _on_reset_button_pressed():
	# on game disconnect
	# functional
	SyncManager.stop()
	SyncManager.clear_peers()
	
	var peer = multiplayer.multiplayer_peer
	
	if peer:
		peer.close()
	
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started():
	# ui for testing
	message_label.text = "started!"
	
	# functional
	if game and game.has_method('reset'):
		game.reset()
	else:
		print("ERROR: GAME NODE NOT FOUND || main.gd -> _on_SyncManager_sync_started()")
	
	# logging, functional
	if logging_enabled:
		var _dir = DirAccess.open(LOG_FILE_DIRECTORY)
		if not DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY):
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)

		var datetime = Time.get_datetime_dict_from_system()
		var log_file_name = '%04d%02d%02d-%02d%02d%02d-peer-%d.log' % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			multiplayer.get_unique_id(),
		]
		
		print(log_file_name)
		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

func _on_SyncManager_sync_stopped():
	# debug for testing
	if logging_enabled: SyncManager.stop_logging()

func _on_SyncManager_sync_lost():
	# ui for testing
	sync_lost_label.visible = true
	
func _on_SyncManager_sync_regained():
	#ui for testing
	sync_lost_label.visible = false
	
func _on_SyncManager_sync_error(msg: String) -> void:
	# ui for testing
	message_label.text = "Fatal sync error :(" + msg
	sync_lost_label.visible = false
	
	# functional code
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()
