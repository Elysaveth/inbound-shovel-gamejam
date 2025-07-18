extends SubViewport

@export var player_path: NodePath
@export var world_extents: Rect2

var player: RigidBody3D

func _ready() -> void:
	player = get_node(player_path)
	if not player:
		set_process(false)

func _process(_delta: float) -> void:
	var half_world_extents = world_extents.size * 0.5
	var player_pos = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)

	player_pos += half_world_extents
	var paintbrush_position = player_pos / world_extents.size
	
	$SnowPaintBrush.position = paintbrush_position * size
