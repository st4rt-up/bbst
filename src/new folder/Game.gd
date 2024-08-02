extends Node2D
# name tbd

@onready var SERVER_PLAYER:Player = $ServerPlayer
@onready var CLIENT_PLAYER:Player = $ClientPlayer

var distance: int

func _ready():
	SERVER_PLAYER.other_player = CLIENT_PLAYER
	CLIENT_PLAYER.other_player = SERVER_PLAYER

func _network_process(_input: Dictionary) -> void:
	distance = max(SERVER_PLAYER.position.x, CLIENT_PLAYER.position.x) - min(SERVER_PLAYER.position.x, CLIENT_PLAYER.position.x)

func reset() -> void:
	return
