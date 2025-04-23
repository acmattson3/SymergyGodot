extends Control

@export var value: float = 0.0:
	set(new_value):
		#$HBoxContainer/ValueLabel.text = str(new_value)
		value = new_value
@export var max_value: float = 10.0
@export var min_value: float = 0.0
@export var step_size: float = 1.0

@export var disabled: bool:
	set(value):
		disabled = value
		$HBoxContainer/VBoxContainer/ButtonUp.disabled = value
		$HBoxContainer/VBoxContainer/ButtonDown.disabled = value

signal value_changed(value: float)

func _ready():
	$HBoxContainer/ValueLabel.text = str(value)

func _on_button_up_pressed():
	if value >= max_value:
		value = max_value
		return
	value += step_size
	$HBoxContainer/ValueLabel.text = str(value)
	value_changed.emit(value)

func _on_button_down_pressed():
	if value <= min_value:
		value = min_value
		return
	value -= step_size
	$HBoxContainer/ValueLabel.text = str(value)
	value_changed.emit(value)

func _on_value_label_text_submitted(new_text: String) -> void:
	value = float(new_text)
	if value < min_value:
		value = min_value
		$HBoxContainer/ValueLabel.text = str(value)
	elif value > max_value:
		value = max_value
		$HBoxContainer/ValueLabel.text = str(value)
		
	value_changed.emit(value)

func _on_value_label_focus_exited() -> void:
	_on_value_label_text_submitted($HBoxContainer/ValueLabel.text)
