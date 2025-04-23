extends PanelContainer
class_name Widget

signal got_clicked(widget)

@export var child_node: Control # The node we are "hosting"
@export var grid_size: int = 16  # Snap-to-grid size

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
	
	got_clicked.emit(self)

func _on_title_bar_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			got_clicked.emit(self)
			_bring_to_front()
			is_dragging = true
			drag_offset = event.position
			accept_event()
		elif not event.pressed:
			SaveManager.add_widget_data(self)
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
	fullscreen = false
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			got_clicked.emit(self)
			_bring_to_front()
			is_resizing = true
			accept_event()
		elif not event.pressed:
			SaveManager.add_widget_data(self)
			is_resizing = false

	elif event is InputEventMouseMotion and is_resizing:
		got_clicked.emit(self)
		var new_size = get_global_mouse_position() - global_position
		size = _snap_to_grid(new_size)
		accept_event()

func terminate() -> void:
	_on_exit_widget()

func _on_exit_widget():
	SaveManager.remove_widget_data(self)
	queue_free()

static func create(new_title: String, elem) -> Widget:
	var new_widget = load("res://ui_elements/widget/widget.tscn").instantiate()
	new_widget.title = new_title
	new_widget.set_content.call_deferred(elem)
	return new_widget

func set_content(new_ui_element):
	content.add_child.call_deferred(new_ui_element)
	child_node = new_ui_element

func handle_startup():
	for i in 3:
		await get_tree().physics_frame
	if not child_node:
		return
	
	SaveManager.add_widget_data(self)
	
	match widget_type:
		WidgetType.MULTILINE:
			child_node.do_init()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		got_clicked.emit(self)
		_bring_to_front()

var fullscreen: bool = false
var prev_size = null
var prev_pos = null
func go_fullscreen():
	if not fullscreen:
		_bring_to_front()
		prev_size = size
		prev_pos = global_position
		global_position = Vector2.ZERO
		var new_size = get_viewport_rect().size
		size = _snap_to_grid(new_size)
		fullscreen = true
	elif prev_size != null and prev_pos != null:
		size = prev_size
		global_position = prev_pos
		fullscreen = false

func _on_full_screen_button_pressed() -> void:
	got_clicked.emit(self)
	go_fullscreen()

func _on_edit_button_pressed() -> void:
	Util.edit_widget.emit(self)
