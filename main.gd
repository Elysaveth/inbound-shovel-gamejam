extends Node3D

func _ready():
	$Player.global_position = $Terrain.pick


func _on_player_game_over() -> void:
	pass
	
