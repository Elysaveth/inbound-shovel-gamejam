extends Node3D

func _ready():
	$Player.global_position = $Terrain.pick
