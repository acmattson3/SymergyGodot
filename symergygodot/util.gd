extends Node

# Expects json_string to be a stringified Dictionary
func get_data_from_json_string(json_string, data_key):
	var data_received = get_dict_from_json_string(json_string)
	if data_received != null:
		if data_received.has(data_key):
			return data_received.value
		else:
			print("Unexpected value from data (", data_key, " not in dictionary).")
			return null
	else:
		return null

func get_dict_from_json_string(json_string: String):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if data_received is Dictionary:
			#print(data_received)
			return data_received
		else:
			print("Unexpected incoming data (non-dictionary).")
			return null
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return null

func val_in_interval(val, min, max, inclusive=true) -> bool:
	if inclusive:
		return val >= min and val <= max
	else:
		return val > min and val < max
