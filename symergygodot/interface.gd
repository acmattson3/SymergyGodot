extends Control

@onready var widgets: Control = $Widgets

# Open widget creation menu
func _on_widget_button_pressed() -> void:
	$WidgetCreationMenu.visible = !$WidgetCreationMenu.visible

# Instantiating Widgets
var widget_type: Widget.WidgetType = Widget.WidgetType.NONE
func _on_widget_option_button_item_selected(index: int) -> void:
	if widget_type == index:
		return
	
	# Hide open widget-specific menus
	for child in $WidgetCreationMenu/WidgetCreationBars.get_children():
		if child.name.count("VBox") > 0:
			child.hide()
	
	widget_type = index
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			%GaugeVBox.show()
		Widget.WidgetType.MULTILINE:
			%MultilineVBox.show()

func _on_create_widget_button_pressed() -> void:
	var widget_title = %WidgetTitleLineEdit.text
	
	var new_widget: Widget = null
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			var max_val = float(%MaxValueLineEdit.text)
			var balanced_val = float(%BalValueLineEdit.text)
			var min_val = float(%MinValueLineEdit.text)
			var update_int = float(%UpdateIntLineEdit.text)
			var unit = %UnitLineEdit.text
			
			var ui_element = ValueGauge.create(max_val, balanced_val, min_val, update_int, unit)
			new_widget = Widget.create(widget_title, ui_element)
			new_widget.widget_type = Widget.WidgetType.GAUGE
			
		Widget.WidgetType.MULTILINE:
			pass
	
	if new_widget != null:
		widgets.add_child(new_widget)
		$WidgetCreationMenu.visible = !$WidgetCreationMenu.visible
	else:
		print("Unable to instantiate widget!")
		%ErrorLabel.text = "Please choose a widget type!"
