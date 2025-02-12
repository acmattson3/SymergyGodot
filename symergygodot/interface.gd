extends Control


@export var has_login_file: bool = false

const BROKER_HOSTNAME: String = "tcp://192.168.40.14:1883"#sssn.us:1883"
var mqtt_host := BROKER_HOSTNAME
func _ready():
	# Connect signals
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.received_message.connect(_on_received_message)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	#MQTTHandler.broker_disconnected.connect(_on_broker_disconnected)
	
	var mqtt_user = ""
	var mqtt_pass = ""
	
	if has_login_file:
		var login_dict = get_dict_from_json_string(FileAccess.open("res://mqtt_login.txt", FileAccess.READ).get_as_text())
		mqtt_user = login_dict["user"]
		mqtt_pass = login_dict["pass"]
	
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--mqtt-host" and i + 1 < args.size():
			mqtt_host = args[i + 1]
		elif args[i] == "--mqtt-user" and i + 1 < args.size():
			mqtt_user = args[i + 1]
		elif args[i] == "--mqtt-pass" and i + 1 < args.size():
			mqtt_pass = args[i + 1]
	print("Username is: "+mqtt_user if mqtt_user != "" else "WARN: Username is empty string!")
	print("Password is not empty." if mqtt_pass != "" else "WARN: Password is empty string!")
	MQTTHandler.set_user_pass(mqtt_user, mqtt_pass)
	MQTTHandler.connect_to_broker(mqtt_host)

var process_multiline_elapsed: float = 1.0
var process_multiline_interval: float = 1.0
var total_source_powers: Dictionary = {}
var total_load_power: float = 0.0
func _physics_process(delta: float) -> void:
	process_multiline_elapsed += delta
	if process_multiline_elapsed >= process_multiline_interval:
		process_multiline_elapsed = 0.0
		total_load_power = 0.0
		total_source_powers = {}
		for id in accumulated_power.keys():
			var power = accumulated_power[id]
			var component = meter_structure[id]
			var type = component.type
			if type == "source":
				# Compile source powers by category
				if total_source_powers.has(component.category):
					total_source_powers[component.category] += power
				else:
					total_source_powers[component.category] = power
			elif type == "load":
				# Compile all load powers together
				total_load_power += power
		var curr_graph = $VBoxContainer/MultilineGraph
		if total_source_powers != {} and total_source_powers.keys().size() == 4:
			curr_graph.set_curr_power(total_load_power, "total_load")
			curr_graph.set_curr_power(total_source_powers["diesel"], "generator")
			curr_graph.set_curr_power(total_source_powers["solar"], "solar")
			curr_graph.set_curr_power(total_source_powers["wind"], "wind")
			curr_graph.set_curr_power(total_source_powers["hydro"], "hydro")
			var total_source = 0.0
			for key in total_source_powers.keys():
				total_source += total_source_powers[key]
			curr_graph.set_curr_power(total_source, "total_source")

func _on_broker_connected():
	print("Connected to the MQTT broker.")
	MQTTHandler.subscribe("symergygrid/meterstructure")
	MQTTHandler.subscribe("symergygrid/components/+/+/voltage") # For voltage teeter/gauge
	MQTTHandler.subscribe("symergygrid/components/+/+/power") # For multiline graph
	$VBoxContainer/MultilineGraph.connected = true

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

func _on_received_message(topic: String, message):
	var topic_portions = topic.split('/')
	match len(topic_portions):
		2:
			if topic == "symergygrid/meterstructure" and meter_structure == {}:
				var incoming_structure = get_dict_from_json_string(message)
				if incoming_structure != null:
					parse_meterstructure(incoming_structure)
		5:
			var component_id = topic_portions[3]
			if topic_portions[4] == "voltage":
				var new_voltage = get_data_from_json_string(message, "value")
				if new_voltage != null:
					handle_incoming_voltage(component_id, new_voltage)
			if topic_portions[4] == "power":
				var new_power = get_data_from_json_string(message, "value")
				if new_power != null:
					handle_incoming_power(component_id, new_power)

var meter_structure: Dictionary = {}
func parse_meterstructure(incoming_structure: Dictionary):
	if incoming_structure == {}:
		print("Empty meter structure!")
		return
	for component in incoming_structure.components:
		var component_id = component.id
		component.erase("id")
		if not component_id in meter_structure.keys():
			meter_structure[component_id] = component
		else:
			print("WARN: Duplicate ID detected in meter structure! Skipping.")

var num_rolling_voltages: int = 50
var curr_rolling_voltage: int = 0
var rolling_voltages := {}
func handle_incoming_voltage(_id: String, voltage: float):
	# Teeter and gauge for system voltage
	rolling_voltages[curr_rolling_voltage] = voltage
	curr_rolling_voltage += 1
	if curr_rolling_voltage >= num_rolling_voltages:
		curr_rolling_voltage = 0
	var average_voltage := 0.0
	for voltage_num in rolling_voltages.keys():
		average_voltage += rolling_voltages[voltage_num]
	average_voltage /= len(rolling_voltages) if len(rolling_voltages) > 0 else 1
	$VBoxContainer/ValueGuage.set_current_value(average_voltage)

var accumulated_power: Dictionary = {}
func handle_incoming_power(id: String, power: float):
	accumulated_power[id] = power # Remember each power for later

func _on_broker_connection_failed():
	print("Failed to connect to the MQTT broker.")
