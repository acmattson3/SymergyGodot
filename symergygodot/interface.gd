extends Control

signal interface_gui_input(event: InputEvent)

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
	
	Util.edit_widget.connect(_on_edit_widget)

var editing: bool = false:
	set(value):
		editing = value
		%TitleLabel.text = "Edit Widget" if editing else "Create Widget"
		clear_creation_menu()
		if not editing:
			widget_editing = null
var widget_editing = null
func _on_edit_widget(widget: Widget):
	widget_editing = widget
	editing = true
	$WidgetCreationMenu.show()
	%WidgetTitleLineEdit.text = widget.title
	%WidgetOptionButton.selected = widget.widget_type
	
	widget_type = widget.widget_type
	match widget.widget_type:
		Widget.WidgetType.GAUGE:
			%GaugeVBox.show()
			%MaxValueLineEdit.text = str(widget.child_node.value_max)
			%BalValueLineEdit.text = str(widget.child_node.value_bal)
			%MinValueLineEdit.text = str(widget.child_node.value_min)
			%SingleLookupLineEdit.text = widget.child_node.curr_component
			%MetricOptionButton.selected = ["voltage", "current", "power", "energy"].find(widget.child_node.curr_metric)
		Widget.WidgetType.MULTILINE:
			%MultilineVBox.show()
			%TitleLineEdit.text = widget.child_node.graph_title
			%YAxisLineEdit.text = widget.child_node.y_label
			%XAxisLineEdit.text = widget.child_node.x_label
			%TickButton.value = widget.child_node.max_samples - 1
			for i in widget.child_node.graphed_components.size():
				var comp = widget.child_node.graphed_components[i]
				var color = widget.child_node.graphed_component_colors[i]
				var metric = widget.child_node.graphed_component_metrics[i]
				
				var new_comp = load("res://ui_elements/listed_component/listed_component.tscn").instantiate()
				new_comp.set_component_name(comp)
				new_comp.color = color
				new_comp.metric = metric
				%CurrCompsVBox.add_child(new_comp)
		_:
			return

func _on_loaded_save_state(save_state: Dictionary):
	for widget_name in save_state.widgets.keys():
		var widget = save_state.widgets[widget_name]
		match widget.type:
			Widget.WidgetType.GAUGE:
				create_gauge_widget(widget)
			Widget.WidgetType.MULTILINE:
				create_multiline_widget(widget)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		await get_tree().process_frame
		if $WidgetCreationMenu.visible:
			$WidgetCreationMenu.hide()
			editing = false
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
	editing = false
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
	var widget_title = %WidgetTitleLineEdit.text
	
	match widget_type:
		Widget.WidgetType.NONE:
			print("Unable to instantiate widget!")
			%ErrorLabel.text = "Please choose a widget type!"
			return
		
		Widget.WidgetType.GAUGE:
			var max_val = float(%MaxValueLineEdit.text if %MaxValueLineEdit.text!="" else %MaxValueLineEdit.placeholder_text)
			var balanced_val = float(%BalValueLineEdit.text if %BalValueLineEdit.text!="" else %BalValueLineEdit.placeholder_text)
			var min_val = float(%MinValueLineEdit.text if %MinValueLineEdit.text!="" else %MinValueLineEdit.placeholder_text)
			var component_id: String = %SingleLookupLineEdit.text
			var component_metric: String = ["voltage", "current", "power", "energy"][%MetricOptionButton.selected]
			
			if component_id == "":
				%ErrorLabel.text = "Please choose a component!"
				return
			if max_val <= min_val:
				%ErrorLabel.text = "Max value must be greater than min value!"
				return
			if not Util.val_in_interval(balanced_val, min_val, max_val, false):
				%ErrorLabel.text = "Balanced value must be between min and max values!"
				return
			
			var widget = {
				"title": widget_title,
				"value_max": max_val,
				"value_bal": balanced_val,
				"value_min": min_val,
				"curr_component": component_id,
				"curr_metric": component_metric,
			}
			create_gauge_widget(widget)
		
		Widget.WidgetType.MULTILINE:
			var graph_title: String = %TitleLineEdit.text
			var y_label: String = %YAxisLineEdit.text
			var x_label: String = %XAxisLineEdit.text
			var max_samples: int = %TickButton.value + 1
			var component_list: Array[Dictionary] = []
			
			if %CurrCompsVBox.get_child_count() <= 0:
				%ErrorLabel.text = "Please add at least one component!"
				return
			for child in %CurrCompsVBox.get_children():
				component_list.append({
					"comp_name": child.get_component_name(), 
					"color": child.get_color(), 
					"metric": child.get_metric()
				})
			
			var widget = {
				"title": widget_title,
				"graph_title": graph_title,
				"y_label": y_label,
				"x_label": x_label,
				"max_samples": max_samples,
				"component_list": component_list
			}
			create_multiline_widget(widget)
	
	$WidgetCreationMenu.hide()

func clear_creation_menu() -> void:
	%ErrorLabel.text = ""
	%GaugeVBox.hide()
	%MultilineVBox.hide()
	%WidgetTitleLineEdit.text = ""
	%WidgetOptionButton.selected = 0
	%MaxValueLineEdit.text = ""
	%BalValueLineEdit.text = ""
	%MinValueLineEdit.text = ""
	%SingleLookupLineEdit.text = ""
	%MetricOptionButton.selected = 0
	%TitleLineEdit.text = ""
	%YAxisLineEdit.text = ""
	%XAxisLineEdit.text = ""
	%TickButton.value = 60
	widget_type = 0
	for child in %CurrCompsVBox.get_children():
		child.queue_free()

func create_widget(ui_element, widget_type, widget) -> void:
	var new_widget: Widget = null
	new_widget = Widget.create(widget.title, ui_element)
	new_widget.got_clicked.connect(_on_widget_got_clicked)
	new_widget.widget_type = widget_type
	
	if widget.has("name"):
		new_widget.name = widget.name
	if widget.has("size"):
		new_widget.size = widget.size
	if widget.has("position"):
		new_widget.global_position = widget.position
	
	if widget_editing != null:
		new_widget.size = widget_editing.size
		new_widget.global_position = widget_editing.global_position
		widget_editing.terminate()
	
	if new_widget != null:
		widgets.add_child(new_widget, true)
		new_widget.handle_startup()

func create_gauge_widget(widget: Dictionary) -> void:
	var ui_element: ValueGauge = ValueGauge.create(widget.value_max, widget.value_bal, widget.value_min)
	
	MQTTHandler.request_new_component_metric(widget.curr_component, widget.curr_metric)
	ui_element.curr_component = widget.curr_component
	ui_element.curr_metric = widget.curr_metric
	
	create_widget(ui_element, Widget.WidgetType.GAUGE, widget)

func create_multiline_widget(widget: Dictionary) -> void:	
	var ui_element: MultilineGraph = MultilineGraph.create()
	
	if widget.component_list.size() <= 0:
		%ErrorLabel.text = "Please add at least one component!"
		return
	for comp: Dictionary in widget.component_list:
		ui_element.add_graphed_component(comp.comp_name, comp.color, comp.metric)
		MQTTHandler.request_new_component_metric(comp.comp_name, comp.metric)
	ui_element.max_samples = widget.max_samples
	ui_element.graph_title = widget.graph_title
	ui_element.y_label = widget.y_label
	ui_element.x_label = widget.x_label
	
	create_widget(ui_element, Widget.WidgetType.MULTILINE, widget)

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

func _on_widgets_gui_input(event: InputEvent) -> void:
	interface_gui_input.emit(event)
