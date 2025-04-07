extends HBoxContainer

@export var component_name: String = "Unnamed Component":
	set(value):
		component_name = value
		$ComponentLabel.text = value

func set_component_name(new_name: String):
	component_name = new_name

func _on_button_pressed() -> void:
	queue_free()

func get_color() -> Color:
	return $ColorPickerButton.color

func get_metric() -> String:
	return ["voltage", "current", "power", "energy"][%MetricOptionButton.selected]

func get_component_name() -> String:
	return component_name
