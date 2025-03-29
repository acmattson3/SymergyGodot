extends PanelContainer

@export var child_node: Control # The node we are "hosting"
@export var grid_size: int = 16  # Snap-to-grid size
@onready var min_size: Vector2 = custom_minimum_size
@export var max_size: Vector2 = Vector2(600, 600)

@onready var title_bar = $VBoxContainer/TitleBar/Panel
@onready var settings_button = $VBoxContainer/TitleBar/Panel/SettingsButton
@onready var resize_handle = $VBoxContainer/BottomBar/ResizeHandle
@onready var content = $VBoxContainer/Content

var is_dragging = false
var drag_offset = Vector2.ZERO
var is_resizing = false

func _ready():
	title_bar.gui_input.connect(_on_title_bar_gui_input)
	resize_handle.gui_input.connect(_on_resize_handle_gui_input)
	settings_button.pressed.connect(_open_settings)
	
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resize_handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	
	child_node.reparent.call_deferred(content)
	#print(child_node.get_parent().name)
	
	#if child_node != null:
	#	child_node.reparent(content)
		#content.add_child(child_node)

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

func _open_settings():
	print("Open settings menu here")  # Replace with your actual settings UI logic

func set_content(new_ui_element: Control):
	content.add_child(new_ui_element)
