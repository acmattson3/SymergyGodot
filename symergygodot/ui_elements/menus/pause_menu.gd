extends Control

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and visible:
		await get_tree().process_frame
		if $SettingsMenu.visible:
			$SettingsMenu.hide()
		else:
			_on_unpause_pressed()

func _on_settings_pressed() -> void:
	$SettingsMenu.show()

func _on_credits_pressed() -> void:
	pass # Replace with function body.

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui_elements/menus/main_menu.tscn")

func _on_unpause_pressed() -> void:
	hide()
	get_tree().paused = false

func do_pause() -> void:
	show()
	get_tree().paused = true
