extends VBoxContainer

signal selection_made(item: String)

@export var lookup_list: Array[String] = [] # The list of things we can select from
var _display_list: Array[String] = [] # The list of results being displayed
@export var max_results: int = 5
var text = "":
	get():
		return $LineEdit.text
	set(value):
		text = value
		$LineEdit.text = value

func _on_line_edit_text_changed(new_text: String) -> void:
	_display_list = []
	if new_text != "":
		for item: String in lookup_list:
			if item == new_text:
				selection_made.emit(item)
			if item.begins_with(new_text):
				_display_list.append(item)
			if _display_list.size() >= max_results:
				break
	
	update_display_list()

func update_display_list() -> void:
	%Panel.global_position.x = global_position.x
	%Panel.global_position.y = global_position.y+size.y+5
	for child in %ResultsVBox.get_children():
		child.queue_free()
	if _display_list.size() == 0:
		%Panel.hide()
	else:
		%Panel.show()
	
	for item in _display_list:
		var new_button = Button.new()
		new_button.text = item
		new_button.pressed.connect(_on_lookup_button_pressed.bind(item))
		%ResultsVBox.add_child(new_button)

func set_lookup_list(list: Array[String]) -> void:
	lookup_list = list.duplicate()

func _on_lookup_button_pressed(item: String):
	$LineEdit.text = item
	_display_list = []
	update_display_list()
	selection_made.emit(item)
