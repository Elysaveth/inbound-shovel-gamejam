extends Control

signal resumed
var paused := false

@export var player: NodePath
var score: Node


func _ready() -> void:
	score = get_node(player)

func _process(delta: float) -> void:
	if score:
		$Info/Label.text = "Score: %.2f" % score.score
	if paused:
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				_on_resume_pressed()


func _on_player_paused() -> void:
	$pause_overlay.visible = true
	await get_tree().create_timer(0.1).timeout
	paused = true


func _on_resume_pressed() -> void:
	paused = false
	$pause_overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resumed.emit()


func _on_retry_pressed() -> void:
	resumed.emit()
	get_tree().change_scene_to_file("res://main.tscn")


func _on_menu_pressed() -> void:
	print("Not yet developed!")
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
