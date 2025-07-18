extends Node3D

func _ready():
	$Ball.global_position = $Terrain.pick
