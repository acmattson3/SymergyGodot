extends Node
# SaveManager
# Handles interface states (saving/loading)

signal loaded_save_state(save_state: Dictionary)

# Our current game state
# Structure:
# _save_state = {
#     "widgets": {
#         "widget_name": {
#             "title": "widget_title",
#             ...
#         }
#         ...
#     }
# } # End game state

const _empty_state := {
	"widgets": {}
}

var save_state: Dictionary = _empty_state.duplicate(true)

var curr_save: String = "autosave":
	set(value):
		curr_save = value
		_save_filepath = "user://"+value+".json"
var _save_filepath: String = "user://autosave.json"
var default_save: String = "autosave"

var save_state_loaded: bool = false
const debugging = false

func _ready():
	pass
	_load_game_from_file() # Load data on startup

func _notification(what):
	# Catch pressing X on the application window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game_to_file() # Save before we close!
		await get_tree().physics_frame
		get_tree().quit() # Do the default behavior too

func _process(_delta):
	# Debugging keyboard shortcut to clear the game save file (likely removed later)
	if Input.is_key_pressed(KEY_F1) and Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_ALT):
		clear_save_file()

func clear_save_file():
	print("Cleared save file!")
	save_state = _empty_state.duplicate(true)
	var file = FileAccess.open(_save_filepath, FileAccess.WRITE)
	file.store_var(save_state, true)

# Save the game state
func _save_game_to_file():
	var which_save_file = FileAccess.open("user://default_save.json", FileAccess.WRITE)
	if which_save_file:
		which_save_file.store_var(curr_save)
		which_save_file.close()
	
	var file = FileAccess.open(_save_filepath, FileAccess.WRITE)
	if file:
		if debugging:
			print(save_state)
		file.store_var(save_state, true)
		file.close()
		print("Saved game data.")
	else:
		print("Failed to save: ", FileAccess.get_open_error())

# Load the game state
func _load_game_from_file():
	var which_save_file = FileAccess.open("user://default_save.json", FileAccess.READ)
	if which_save_file:
		var save = which_save_file.get_var(true)
		if save:
			curr_save = save
	
	var file = FileAccess.open(_save_filepath, FileAccess.READ)
	if file:
		var new_save_state = file.get_var(true)
		if new_save_state:
			save_state = new_save_state
			if debugging:
				print(save_state)
			print("Loaded save state.")
			save_state_loaded = true
		else:
			print("Failed to load save state!")
		file.close()
	else:
		print("Failed to load: ", FileAccess.get_open_error())
	
	loaded_save_state.emit(save_state)

func add_widget_data(widget: Widget):
	var new_widget_data := {
		"title": widget.title,
		"position": widget.global_position,
		"size": widget.size,
		"type": widget.widget_type,
		"name": widget.name
	}
	
	if widget.child_node == null:
		return # No child node means an invalid widget.
	
	match widget.widget_type:
		Widget.WidgetType.GAUGE:
			new_widget_data["value_max"] = widget.child_node.value_max
			new_widget_data["value_bal"] = widget.child_node.value_bal
			new_widget_data["value_min"] = widget.child_node.value_min
			new_widget_data["curr_component"] = widget.child_node.curr_component
			new_widget_data["curr_metric"] = widget.child_node.curr_metric
		Widget.WidgetType.MULTILINE:
			new_widget_data["graph_title"] = widget.child_node.graph_title
			new_widget_data["y_label"] = widget.child_node.y_label
			new_widget_data["x_label"] = widget.child_node.x_label
			new_widget_data["max_samples"] = widget.child_node.max_samples
			new_widget_data["component_list"] = widget.child_node.get_component_dict_array()
		_:
			return
	
	save_state["widgets"][widget.name] = new_widget_data
	_save_game_to_file.call_deferred()

func remove_widget_data(widget: Widget):
	save_state["widgets"].erase(widget.name)
	_save_game_to_file.call_deferred()

func new_save_file(new_save: String):
	curr_save = new_save
	_load_game_from_file()

func is_save_state_loaded() -> bool:
	return save_state_loaded

func get_save_state() -> Dictionary:
	return save_state
