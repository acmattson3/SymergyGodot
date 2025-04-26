extends Node2D

@export var camera: Camera2D # Assign your Camera2D node in the inspector
@export var zoom_speed: float = 0.1  # Speed of zooming
@export var min_zoom: float = 0.5  # Minimum zoom level
@export var max_zoom: float = 10.0  # Maximum zoom level
@export var pan_speed: float = 2.0 # Pan speed multiplier
@export var base_scale: float = 0.2
@export var sensitivity: float = 0.5

var dragging: bool = false
var prev_mouse_pos: Vector2

func gui_input(event: InputEvent):
	if camera == null:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	
	elif event is InputEventMouseMotion and dragging:
		var screen_delta = event.relative * pan_speed
		var world_delta = screen_delta * camera.zoom.x
		camera.position -= world_delta*sensitivity
	
	# Scroll to zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= (1 - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= (1 + zoom_speed)

		# Clamp zoom level
		camera.zoom.x = clamp(camera.zoom.x, min_zoom, max_zoom)
		camera.zoom.y = clamp(camera.zoom.y, min_zoom, max_zoom)
		scale_component_icons()

func _ready() -> void:
	MQTTHandler.meterstructure_broadcast.connect(_on_meterstructure_broadcast)
	if MQTTHandler.has_meterstructure():
		_on_meterstructure_broadcast(MQTTHandler.get_meterstructure())

var components: Array[String] = []
func _on_meterstructure_broadcast(meter_structure: Dictionary):
	for child in $Components.get_children():
		child.queue_free()
	# Set up each component node
	for comp_id in meter_structure.keys():
		var component_info = meter_structure[comp_id]
		var new_component: Component = Component.create(
			comp_id,
			component_info.type,
			component_info.category,
			component_info.name,
			component_info.coordinates.lat,
			component_info.coordinates.lon
		)
		$Components.add_child(new_component)
	
	create_connections.call_deferred(meter_structure)
	position_components.call_deferred()
	draw_connections.call_deferred()
	scale_component_icons.call_deferred()

func create_connections(meter_structure: Dictionary):
	for child in $Components.get_children():
		if child is not Component:
			return
		var comp_id = child.name
		var component_info = meter_structure[comp_id]
		for connection in component_info.connections:
			for component in $Components.get_children():
				if component is Component and component.id == connection:
					child.add_connection(component)
					break

func position_components():
	var components = $Components.get_children()
	if components.is_empty():
		return

	var sum_lat = 0.0
	var sum_lon = 0.0
	var positions = []

	# Collect lat/lon values
	for component: Component in components:
		if component.has_method("get_latitude") and component.has_method("get_longitude"):
			var lat = component.get_latitude()
			var lon = component.get_longitude()
			sum_lat += lat
			sum_lon += lon
			positions.append(Vector2(lon, lat))
	
	# Compute average center
	var count = positions.size()
	if count == 0:
		return

	var avg_lat = sum_lat / count
	var avg_lon = sum_lon / count
	
	# Adjust positions relative to average
	var adjusted_positions = []
	for i in range(count):
		adjusted_positions.append(Vector2(
			positions[i].x - avg_lon,
			-2*(positions[i].y - avg_lat)
		))

	# Find bounding box
	var min_x = adjusted_positions[0].x
	var max_x = adjusted_positions[0].x
	var min_y = adjusted_positions[0].y
	var max_y = adjusted_positions[0].y

	for pos in adjusted_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	var width = max_x - min_x
	var height = max_y - min_y

	# Get the size of the camera window
	var screen_size = get_viewport_rect().size
	var margin = 0.2  # 10% padding

	# Determine scale to fit within camera view
	var scale_x = (screen_size.x * (1 - margin)) / width if width > 0 else 1
	var scale_y = (screen_size.y * (1 - margin)) / height if height > 0 else 1
	var scale_factor = min(scale_x, scale_y)  # Maintain aspect ratio

	# Apply new positions
	for i in range(count):
		components[i].position = adjusted_positions[i] * scale_factor

func draw_connections() -> void:
	var existing_connections := {}  # Dictionary to track created connections

	# Iterate over all BaseComponent children
	for component in $Components.get_children():
		if component is not Component:
			continue  # Skip non-BaseComponent nodes
		for connected_component in component.connections:
			if not connected_component or connected_component is not Component:
				continue  # Ensure valid connection
			
			# Create a unique key to prevent duplicate connections (order-independent)
			var connection_key = get_connection_key(component, connected_component)
			
			if connection_key in existing_connections:
				continue  # Connection already exists
			
			# Create and configure the Connection2D
			var connection = Connection2D.new()
			connection.width = 1
			connection.connection_a = component
			connection.connection_b = connected_component
			connection.default_color = Color.YELLOW
			connection.points = PackedVector2Array([connection.connection_a.position, connection.connection_b.position])
			
			# Add to scene and track it
			$Components.add_child(connection)
			#connection.reparent($Components)  # Ensure it's inside $Components
			existing_connections[connection_key] = connection

# Helper function to create a unique key for each connection
func get_connection_key(a: Component, b: Component) -> String:
	var sorted_ids = [a.id, b.id]
	sorted_ids.sort()  # Ensures order-independent key
	return sorted_ids[0]+"-"+sorted_ids[1]

func scale_component_icons():
	var scale_factor: float = base_scale / camera.zoom.x
	#sensitivity = 0.5*camera.zoom.x
	for component in $Components.get_children():
		if component is Component:
			component.scale_icon(scale_factor)
