extends PanelContainer
class_name Widget

@export var child_node: Control # The node we are "hosting"
@export var grid_size: int = 16  # Snap-to-grid size
@onready var min_size: Vector2 = custom_minimum_size
@export var max_size: Vector2 = Vector2(600, 600)

@onready var title_bar = $VBoxContainer/TitleBar
@onready var exit_button = $VBoxContainer/TitleBar/HBoxContainer/ExitButton
@onready var resize_handle = $VBoxContainer/BottomBar/ResizeHandle
@onready var content = $VBoxContainer/Content
@export var title: String = "Unnamed Widget":
	set(value):
		title = value
		%TitleLabel.text = value
enum WidgetType { NONE, GAUGE, MULTILINE }
@export var widget_type: WidgetType = WidgetType.NONE
enum WidgetMode { SINGLE, GROUP, CUSTOM }
@export var widget_mode: WidgetMode = WidgetMode.SINGLE

var is_dragging = false
var drag_offset = Vector2.ZERO
var is_resizing = false

func _ready():
	title_bar.gui_input.connect(_on_title_bar_gui_input)
	resize_handle.gui_input.connect(_on_resize_handle_gui_input)
	exit_button.pressed.connect(_on_exit_widget)
	
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	exit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resize_handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	
	#child_node.reparent.call_deferred(content)
	#print(child_node.get_parent().name)
	
	#if child_node != null:
	#	child_node.reparent(content)
		#content.add_child(child_node)

var curr_component: String = ""
var curr_metric: String = ""
func _physics_process(delta: float) -> void:
	match widget_type:
		WidgetType.NONE:
			pass
		WidgetType.GAUGE:
			if widget_mode == WidgetMode.SINGLE and curr_component != "":
				var package = MQTTHandler.get_component_metric(curr_component, curr_metric)
				if package != null:
					child_node.set_current_value(package.value)
				#child_node.set_current_unit(package.unit)
		WidgetType.MULTILINE:
			_process_multiline(delta)

func _on_title_bar_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_bring_to_front()
			is_dragging = true
			drag_offset = event.position
			accept_event()
		elif not event.pressed:
			is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var new_position = get_global_mouse_position() - drag_offset
		global_position = _snap_to_grid(new_position)
		accept_event()

func _bring_to_front():
	if get_parent():  # Ensure the widget has a parent
		get_parent().move_child(self, -1)  # Moves this node to the last index (topmost)

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size
	)

func _on_resize_handle_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_bring_to_front()
			is_resizing = true
			accept_event()
		elif not event.pressed:
			is_resizing = false

	elif event is InputEventMouseMotion and is_resizing:
		var new_size = (get_global_mouse_position() - global_position).clamp(min_size, max_size)
		size = _snap_to_grid(new_size)
		accept_event()

func _on_exit_widget():
	queue_free()

static func create(title: String, elem) -> Widget:
	var new_widget = load("res://ui_elements/widget/widget.tscn").instantiate()
	new_widget.title = title
	new_widget.set_content.call_deferred(elem)
	return new_widget

func set_content(new_ui_element):
	content.add_child.call_deferred(new_ui_element)
	child_node = new_ui_element

func handle_startup():
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not child_node:
		return
	match widget_type:
		WidgetType.MULTILINE:
			child_node.do_init()

func _process_multiline(delta: float) -> void:
	return # Ignore this for now

func _process_value_gauge(delta: float) -> void:
	return
