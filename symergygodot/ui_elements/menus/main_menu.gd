extends Control

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		$SettingsMenu.hide()

func _on_start_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://interface.tscn")
	
func _on_settings_pressed() -> void:
	$SettingsMenu.show()
	
func _on_credits_pressed() -> void:
	pass # Replace with function body.
	
func _on_exit_pressed() -> void:
	get_tree().quit()
