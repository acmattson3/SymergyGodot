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

var _save_state := _empty_state

var curr_save: String = "autosave":
	set(value):
		curr_save = value
		_save_filepath = "user://"+value+".json"
var _save_filepath: String = "user://autosave.json"
var default_save: String = "autosave"

var save_state_loaded: bool = false
const debugging = true

func _ready():
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
	_save_state = _empty_state
	var file = FileAccess.open(_save_filepath, FileAccess.WRITE)
	file.store_var(_save_state, true)

# Save the game state
func _save_game_to_file():
	var which_save_file = FileAccess.open("user://default_save.json", FileAccess.WRITE)
	if which_save_file:
		which_save_file.store_var(curr_save)
		which_save_file.close()
	
	var file = FileAccess.open(_save_filepath, FileAccess.WRITE)
	if file:
		if debugging:
			print(_save_state)
		file.store_var(_save_state, true)
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
			_save_state = new_save_state
			if debugging:
				print(_save_state)
			print("Loaded save state.")
			save_state_loaded = true
		else:
			print("Failed to load save state!")
		file.close()
	else:
		print("Failed to load: ", FileAccess.get_open_error())
	
	loaded_save_state.emit(_save_state)

func add_widget_data(widget: Widget):
	_save_state.widgets[widget.name] = widget
	_save_game_to_file.call_deferred()

func new_save_file(new_save: String):
	curr_save = new_save
	_load_game_from_file()

func is_save_state_loaded() -> bool:
	return save_state_loaded

func get_save_state() -> Dictionary:
	return _save_state
