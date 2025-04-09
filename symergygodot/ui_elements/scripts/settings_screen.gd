extends Control

@export var SENSITIVITYSLIDER : HSlider
@export var SENSITVITYNUMBER : Label
@export var FOVSLIDER : HSlider
@export var FOVNUMBER : Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	sensitivity_change_value()
	fov_change_value()

func sensitivity_change_value() -> void:
	SENSITVITYNUMBER.text = str(SENSITIVITYSLIDER.value)
	
func fov_change_value() -> void:
	FOVNUMBER.text = str(FOVSLIDER.value)
	
func _on_exit_settings_pressed() -> void:
	# FIGURE OUT A WAY TO TRANSFER BACK TO PREVIOUS SCENE, NOT JUST INTERFACE.
	get_tree().change_scene_to_file("res://interface.tscn")
