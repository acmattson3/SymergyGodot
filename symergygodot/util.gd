extends Node

func get_dict_from_json_string(json_string: String):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if data_received is Dictionary:
			return data_received
		else:
			print("Unexpected incoming data (non-dictionary).")
			return null
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return null

func val_in_interval(val, in_min, in_max, inclusive=true) -> bool:
	if inclusive:
		return val >= in_min and val <= in_max
	else:
		return val > in_min and val < in_max
