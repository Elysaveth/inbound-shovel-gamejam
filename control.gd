extends Control

signal resumed

func _on_player_paused() -> void:
	$pause_overlay.visible = true


func _on_resume_pressed() -> void:
	$pause_overlay.visible = false
	resumed.emit()


func _on_retry_pressed() -> void:
	resumed.emit()
	get_tree().change_scene_to_file("res://main.tscn")


func _on_menu_pressed() -> void:
	print("Not yet developed!")
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
