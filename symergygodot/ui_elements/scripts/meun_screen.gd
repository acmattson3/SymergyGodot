extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_back_pressed() -> void:
	visible = false
	
func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_credits_pressed() -> void:
	pass # Replace with function body.

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://mainmenu.tscn")
