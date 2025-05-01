extends Node2D
class_name Component

enum ComponentType { NONE, SOURCE, LOAD, DIST }

# Current grid info.
var current_voltage: float = 0.0: # V
	set(value):
		current_voltage = value
		%VoltageLabel.text = "%0.2f" % value 
var current_demand: float  = 0.0: # A
	set(value):
		current_demand = value
		%CurrentLabel.text = "%0.2f" % value 
var current_power: float   = 0.0: # kW
	set(value):
		current_power = value
		%PowerLabel.text = "%0.2f" % value 
var current_energy: float  = 0.0: # kWh
	set(value):
		current_energy = value
		%EnergyLabel.text = "%0.2f" % value 
var current_status: bool = true:
	set(value):
		current_status = value
		%StatusLabel.text = "Running" if value else "Stopped"

@export var latitude: float = 0.0
@export var longitude: float = 0.0
# Component information
@export var id: StringName = ""
@export var type: ComponentType = ComponentType.NONE
@export var category: String = "none"
@export var disp_name: String = "Unnamed Component"
@export var connections: Array[Component] = []

var tooltip_scale := 4.0

static func create(
		in_id: String, 
		in_type: String, 
		in_category: String, 
		in_disp_name: String, 
		in_lat: float, in_lon: float
	) -> Component:
	var new_comp: Component = load("res://feedline/component.tscn").instantiate()
	new_comp.set_id(in_id)
	new_comp.set_type_by_string(in_type)
	new_comp.set_category(in_category)
	new_comp.set_disp_name(in_disp_name)
	new_comp.set_latitude(in_lat)
	new_comp.set_longitude(in_lon)
	return new_comp

func _ready() -> void:
	id = name
	MQTTHandler.request_new_component_metric(id, "voltage")
	MQTTHandler.request_new_component_metric(id, "current")
	MQTTHandler.request_new_component_metric(id, "power")
	MQTTHandler.request_new_component_metric(id, "energy")
	MQTTHandler.request_new_component_metric(id, "status")
	
	Util.change_tooltip_scale.connect(_on_change_tooltip_scale)
	
	if "airport" in id:
		$Airport.show()
	elif "generator" in id:
		$Generator.show()
	elif category == "distribution":
		$Area2D/GeneralCollisionShape.disabled = true
		$Area2D/PoleCollisionShape.disabled = false
		$Pole.show()
	elif category == "solar":
		$Solar.show()
	elif category == "wind":
		$Wind.show()
	elif category == "hydro":
		$Hydro.show()
	elif category == "residential":
		$ResidentialBuilding.show()
	elif category == "commercial" or category == "municipal":
		$CommercialBuilding.show()
	else:
		$CommercialBuilding.show()

func _on_change_tooltip_scale(value: float):
	tooltip_scale = value
	scale_icon(scale_factor)

var update_interval := 0.5
var update_elapsed := 0.0
func _process(delta: float) -> void:
	update_elapsed += delta
	if update_elapsed >= update_interval:
		update_elapsed = 0.0
		var package = MQTTHandler.get_component_metric(id, "voltage")
		if package:
			current_voltage = package.value
		package = MQTTHandler.get_component_metric(id, "current")
		if package:
			current_demand = package.value
		package = MQTTHandler.get_component_metric(id, "power")
		if package:
			current_power = package.value
		package = MQTTHandler.get_component_metric(id, "energy")
		if package:
			current_energy = package.value
		package = MQTTHandler.get_component_metric(id, "status")
		if package:
			current_status = package.value
			

func get_latitude():
	return latitude
func set_latitude(lat: float) -> void:
	latitude = lat
func set_latitude_by_string(lat: String) -> void:
	latitude = lat.to_float()
func get_longitude():
	return longitude
func set_longitude(lon: float) -> void:
	longitude = lon
func set_longitude_by_string(lon: String) -> void:
	longitude = lon.to_float()

func get_connections() -> Array[Component]:
	return connections
func add_connection(new_node: Component) -> bool:
	if not new_node in connections:
		connections.append(new_node)
		return true
	return false
func remove_connection(rem_node: Component) -> bool:
	if rem_node in connections:
		connections.erase(rem_node)
		return true
	return false
func clear_connections() -> void:
	connections.clear()

func get_component_info() -> Dictionary:
	var formatted_connections = []
	for connection in connections:
		formatted_connections.append(connection.get_id())
	
	var formatted_info = {
	  "id": id,
	  "type": get_type_string(),
	  "category": get_category(),
	  "name": name,
	  "coordinates": {"lat": get_latitude(), "lon": get_longitude(), "alt": 0.0},
	  "connections": formatted_connections
	}
	return formatted_info

func get_category() -> String:
	return category
func set_category(new_category: String) -> void:
	category = new_category

func get_disp_name() -> String:
	return disp_name
func set_disp_name(new_disp_name: String) -> void:
	disp_name = new_disp_name

func get_type_string() -> String:
	match type:
		ComponentType.SOURCE:
			return "source"
		ComponentType.LOAD:
			return "load"
		_:	
			return "none"
func set_type(new_type: ComponentType) -> void:
	type = new_type
func set_type_by_string(new_type: String) -> void:
	match new_type:
		"source":
			type = ComponentType.SOURCE
		"load":
			type = ComponentType.LOAD
		"distribution":
			type = ComponentType.DIST

func get_id() -> String:
	return id
func set_id(new_id: String) -> void:
	id = new_id
	name = new_id
	%IDLabel.text = new_id

var scale_factor: float = 0.2
func scale_icon(new_scale_factor: float):
	scale_factor = new_scale_factor
	scale = Vector2.ONE * scale_factor
	$Tooltip.scale = Vector2.ONE * scale_factor * tooltip_scale

func _on_area_2d_mouse_entered() -> void:
	if get_parent():  # Ensure the widget has a parent
		get_parent().move_child(self, -1)  # Moves this node to the last index (topmost)
	$Tooltip.show()
	$Tooltip.global_position = get_global_mouse_position()

func _on_area_2d_mouse_exited() -> void:
	$Tooltip.hide()
