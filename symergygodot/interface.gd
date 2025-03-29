extends Control


func _ready():
	pass

func _physics_process(delta: float) -> void:
	pass

# Open widget creation menu
func _on_widget_button_pressed() -> void:
	$WidgetCreationMenu.visible = !$WidgetCreationMenu.visible # Toggle visibility
