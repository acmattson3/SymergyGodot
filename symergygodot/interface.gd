extends Control

@onready var widgets: Control = $Widgets

func _ready():
	if MQTTHandler.is_connected_to_broker():
		_on_broker_connected(MQTTHandler.get_broker_hostname())
	if MQTTHandler.has_meterstructure():
		_on_meterstructure_broadcast(MQTTHandler.get_meterstructure())
	
	MQTTHandler.meterstructure_broadcast.connect(_on_meterstructure_broadcast)
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	
	SaveManager.loaded_save_state.connect(_on_loaded_save_state)
	if SaveManager.is_save_state_loaded():
		_on_loaded_save_state(SaveManager.get_save_state())

func _on_loaded_save_state(save_state: Dictionary):
	for widget_name in save_state.widgets.keys():
		var widget = create_widget(save_state.widgets[widget_name])
		if widget != null:
			var new_widget: Widget = widget
			widgets.add_child.call_deferred(new_widget)
			new_widget.handle_startup()
		else:
			print("Invalid widget in save state!")

func create_widget(widget_data: Dictionary = {}):
	var widget_title = widget_data.title if widget_data != {} else %WidgetTitleLineEdit.text
	
	if widget_data == {}:
		widget_type = widget_data.type
	
	var new_widget: Widget = null
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			var data_mode: int
			if widget_data != {}:
				data_mode = widget_data.data_mode
			else:
				data_mode = %DataModeOptionButton.selected
			match data_mode:
				0: # Single
					var component_id: String
					if widget_data != {}:
						component_id = widget_data.component_id
					else:
						component_id = %SingleLookupLineEdit.text
					if component_id == "":
						%ErrorLabel.text = "Please choose a component!"
						return
				1: # Group
					pass
				2: # Custom
					pass
			var max_val
			var balanced_val
			var min_val
			var update_int
			var unit
			if widget_data != {}:
				max_val = widget_data.max_val
				balanced_val = widget_data.balanced_val
				min_val = widget_data.min_val
				update_int = widget_data.update_int
				unit = widget_data.unit
			else:
				max_val = float(%MaxValueLineEdit.text if %MaxValueLineEdit.text!="" else %MaxValueLineEdit.placeholder_text)
				balanced_val = float(%BalValueLineEdit.text if %BalValueLineEdit.text!="" else %BalValueLineEdit.placeholder_text)
				min_val = float(%MinValueLineEdit.text if %MinValueLineEdit.text!="" else %MinValueLineEdit.placeholder_text)
				update_int = float(%UpdateIntLineEdit.text if %UpdateIntLineEdit.text!="" else %UpdateIntLineEdit.placeholder_text)
				unit = %UnitLineEdit.text
			
			if max_val <= min_val:
				%ErrorLabel.text = "Max value must be greater than min value!"
				return
			if not Util.val_in_interval(balanced_val, min_val, max_val, false):
				%ErrorLabel.text = "Balanced value must be between min and max values!"
				return
			
			var ui_element: ValueGauge = ValueGauge.create(max_val, balanced_val, min_val, update_int, unit)
			new_widget = Widget.create(widget_title, ui_element)
			new_widget.got_clicked.connect(_on_widget_got_clicked)
			new_widget.widget_type = Widget.WidgetType.GAUGE
			
			match data_mode:
				0: # Single
					var component_id: String
					var component_metric: String
					if widget_data != {}:
						component_id = widget_data.component_id
						component_metric = widget_data.component_metric
					else:
						component_id = %SingleLookupLineEdit.text
						component_metric = ["voltage", "current", "power", "energy"][%MetricOptionButton.selected]
					MQTTHandler.request_new_component_metric(component_id, component_metric)
					new_widget.curr_component = component_id
					new_widget.curr_metric = component_metric
				1: # Group
					pass
				2: # Custom
					pass
			
		Widget.WidgetType.MULTILINE:
			var ui_element: MultilineGraph = MultilineGraph.create()
			
			if %CurrCompsVBox.get_child_count() <= 0:
				%ErrorLabel.text = "Please add at least one component!"
				return
			for child in %CurrCompsVBox.get_children():
				ui_element.add_graphed_component(child.get_component_name(), child.get_color(), child.get_metric())
				MQTTHandler.request_new_component_metric(child.get_component_name(), child.get_metric())
			ui_element.max_samples = %TickButton.value + 1
			if %TitleLineEdit.text != "":
				ui_element.graph_title = %TitleLineEdit.text
			if %YAxisLineEdit.text != "":
				ui_element.y_label = %YAxisLineEdit.text
			if %XAxisLineEdit.text != "":
				ui_element.x_label = %XAxisLineEdit.text
			new_widget = Widget.create(widget_title, ui_element)
			new_widget.widget_type = Widget.WidgetType.MULTILINE
	
	if new_widget != null:
		widgets.add_child(new_widget)
		new_widget.handle_startup()
		$WidgetCreationMenu.visible = !$WidgetCreationMenu.visible
		if widget_data == {}:
			SaveManager.add_widget_data(new_widget.get_widget_data())
	else:
		print("Unable to instantiate widget!")
		%ErrorLabel.text = "Please choose a widget type!"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		await get_tree().process_frame
		if $WidgetCreationMenu.visible:
			$WidgetCreationMenu.hide()
		else:
			$PauseMenu.do_pause()
	if Input.is_action_just_pressed("fullscreen"):
		if widget_in_focus != null:
			widget_in_focus.go_fullscreen()

func _on_broker_connected(_mqtt_host):
	$ConnectingLabel.hide()

func _on_broker_connection_failed(_mqtt_host):
	$ConnectingLabel.show()
	$ConnectingLabel.text = "MQTT connection failed! Please restart and try again."

func _on_meterstructure_broadcast(meter_structure: Dictionary):
	var id_list: Array[String] = []
	for key in meter_structure.keys():
		id_list.append(key)
	%LookupBox.set_lookup_list(id_list)

# Open widget creation menu
func _on_widget_button_pressed() -> void:
	$WidgetCreationMenu.visible = !$WidgetCreationMenu.visible

# Instantiating Widgets
var widget_type: Widget.WidgetType = Widget.WidgetType.NONE
func _on_widget_option_button_item_selected(index: int) -> void:
	if widget_type == index:
		return
	
	%LookupBox.search_for()
	
	# Hide open widget-specific menus
	for child in %WidgetCreationBars.get_children():
		if child.name.count("VBox") > 0:
			child.hide()
	
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			%GaugeVBox.hide()
		Widget.WidgetType.MULTILINE:
			%MultilineVBox.hide()
	
	widget_type = index
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			%GaugeVBox.show()
		Widget.WidgetType.MULTILINE:
			%MultilineVBox.show()

func _on_create_widget_button_pressed() -> void:
	create_widget()

func _on_lookup_box_selection_made(item: String) -> void:
	%LookupBox.search_for()
	match widget_type:
		Widget.WidgetType.NONE:
			pass
		Widget.WidgetType.GAUGE:
			%SingleLookupLineEdit.text = item
		Widget.WidgetType.MULTILINE:
			var new_comp = load("res://ui_elements/listed_component/listed_component.tscn").instantiate()
			new_comp.set_component_name(item)
			%CurrCompsVBox.add_child(new_comp)
			%LookupLineEdit.text = ""

func _on_lookup_line_edit_text_changed(new_text: String) -> void:
	%LookupBox.search_for(new_text)

var widget_in_focus = null
func _on_widget_got_clicked(widget):
	if widget_in_focus != widget:
		widget_in_focus = widget
