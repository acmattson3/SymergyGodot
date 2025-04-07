extends Control

@onready var widgets: Control = $Widgets

func _ready():
	MQTTHandler.meterstructure_broadcast.connect(_on_meterstructure_broadcast)
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)

func _on_broker_connected():
	$ConnectingLabel.hide()

func _on_broker_connection_failed():
	$ConnectingLabel.show()
	$ConnectingLabel.text = "MQTT connection failed! Please restart and try again."

func _on_meterstructure_broadcast(meter_structure: Dictionary):
	var id_list: Array[String] = []
	for key in meter_structure.keys():
		id_list.append(key)
	%SingleLookupLineEdit.set_lookup_list(id_list)

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
	
	var data_mode: int = %DataModeOptionButton.selected
	match data_mode:
		0: # Single
			var component_id: String = %SingleLookupLineEdit.text
			if component_id == "":
				%ErrorLabel.text = "Please choose a component!"
				return
		1: # Group
			pass
		2: # Custom
			pass
	
	var new_widget: Widget = null
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			var max_val = float(%MaxValueLineEdit.text if %MaxValueLineEdit.text!="" else %MaxValueLineEdit.placeholder_text)
			var balanced_val = float(%BalValueLineEdit.text if %BalValueLineEdit.text!="" else %BalValueLineEdit.placeholder_text)
			var min_val = float(%MinValueLineEdit.text if %MinValueLineEdit.text!="" else %MinValueLineEdit.placeholder_text)
			var update_int = float(%UpdateIntLineEdit.text if %UpdateIntLineEdit.text!="" else %UpdateIntLineEdit.placeholder_text)
			var unit = %UnitLineEdit.text
			
			var ui_element = ValueGauge.create(max_val, balanced_val, min_val, update_int, unit)
			new_widget = Widget.create(widget_title, ui_element)
			new_widget.widget_type = Widget.WidgetType.GAUGE
			
			match data_mode:
				0: # Single
					var component_id: String = %SingleLookupLineEdit.text
					var component_metric: String = ["voltage", "current", "power", "energy"][%MetricOptionButton.selected]
					MQTTHandler.request_new_component_metric(component_id, component_metric)
					new_widget.curr_component = component_id
					new_widget.curr_metric = component_metric
				1: # Group
					pass
				2: # Custom
					pass
			
		Widget.WidgetType.MULTILINE:
			pass
	
	if new_widget != null:
		widgets.add_child(new_widget)
		$WidgetCreationMenu.visible = !$WidgetCreationMenu.visible
	else:
		print("Unable to instantiate widget!")
		%ErrorLabel.text = "Please choose a widget type!"
