extends Control

@export var SENSITIVITYSLIDER : HSlider
@export var SENSITVITYNUMBER : Label
@export var FOVSLIDER : HSlider
@export var FOVNUMBER : Label
	
func _on_exit_settings_pressed() -> void:
	hide()

func _on_sensitivity_slider_value_changed(value: float) -> void:
	SENSITVITYNUMBER.text = str(SENSITIVITYSLIDER.value)

func _on_fov_slider_value_changed(value: float) -> void:
	FOVNUMBER.text = str(FOVSLIDER.value)
