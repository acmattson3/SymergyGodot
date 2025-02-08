extends Control


func _ready():
	# Connect signals
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.received_message.connect(_on_received_message)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	
	# Connect to the broker
	MQTTHandler.connect_to_broker("tcp://test.mosquitto.org:1883")

func _on_broker_connected():
	print("Connected to the MQTT broker.")
	MQTTHandler.subscribe("symergygrid/components/+/voltage") # For voltage teeter

# Expects json_string to be a stringified Dictionary
func get_data_from_json_string(json_string, data_key):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if data_received is Dictionary and data_received.has(data_key):
			#print(data_received)
			return data_received.value
		else:
			print("Unexpected data")
			return null
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return null

var num_rolling_voltages: int = 10
var curr_rolling_voltage: int = 0
var rolling_voltages := {}
func _on_received_message(_topic, message):
	# Teeter for voltage
	var new_voltage = get_data_from_json_string(message, "value")
	if new_voltage != null:
		rolling_voltages[curr_rolling_voltage] = new_voltage
		curr_rolling_voltage += 1
		if curr_rolling_voltage >= num_rolling_voltages:
			curr_rolling_voltage = 0
	var average_voltage := 0.0
	for voltage_num in rolling_voltages.keys():
		average_voltage += rolling_voltages[voltage_num]
	average_voltage /= len(rolling_voltages) if len(rolling_voltages) > 0 else 1
	$VoltageTeeter.set_current_value(average_voltage)

func _on_broker_connection_failed():
	print("Failed to connect to the MQTT broker.")
