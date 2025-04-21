extends PanelContainer

signal selection_made(item: String)

@export var lookup_list: Array[String] = [] # The list of things we can select from
var _display_list: Array[String] = [] # The list of results being displayed

func search_for(text: String = "") -> void:
	_display_list = []
	if text != "":
		for item: String in lookup_list:
			if text in item:
				_display_list.append(item)
	else:
		_display_list = lookup_list
	
	update_display_list()

func update_display_list() -> void:
	for child in %ResultsVBox.get_children():
		child.queue_free()
	if _display_list.size() == 0:
		%NoneFoundLabel.show()
	else:
		%NoneFoundLabel.hide()
	
	for item in _display_list:
		var new_button = Button.new()
		new_button.text = item
		new_button.pressed.connect(_on_lookup_button_pressed.bind(item))
		%ResultsVBox.add_child(new_button)

func set_lookup_list(list: Array[String]) -> void:
	lookup_list = list.duplicate()
	_display_list = lookup_list
	update_display_list()

func _on_lookup_button_pressed(item: String):
	_display_list = []
	update_display_list()
	selection_made.emit(item)
