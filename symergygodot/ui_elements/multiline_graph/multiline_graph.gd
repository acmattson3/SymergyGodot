extends Control
class_name MultilineGraph

@onready var chart: Chart = $Chart
@export var max_samples: int = 60
@export var graph_title: String = "Untitled Graph"
@export var x_label: String = "Time (s)"
@export var y_label: String = "Variable"

var graphed_components: Array[String] = []
var graphed_component_colors: Array[Color] = []
var graphed_component_metrics: Array[String] = []

func get_component_dict_array() -> Array:
	var comp_array = []
	
	for i in range(graphed_components.size()):
		var comp_dict = {}
		comp_dict["comp_name"] = graphed_components[i]
		comp_dict["color"] = graphed_component_colors[i]
		comp_dict["metric"] = graphed_component_metrics[i]
		
		comp_array.append(comp_dict)
	
	return comp_array

func add_graphed_component(new_component: String, color: Color, metric: String) -> void:
	if done_init:
		return # We can't add a new function if we have initialized!
	graphed_components.append(new_component)
	graphed_component_colors.append(color)
	graphed_component_metrics.append(metric)

static func create() -> MultilineGraph:
	return load("res://ui_elements/multiline_graph/multiline_graph.tscn").instantiate()

# Plot these functions
#var f_gen: Function
#var f_solar: Function
#var f_wind: Function
#var f_hydro: Function
#var f_load_total: Function
#var f_source_total: Function
var component_functions: Array[Function] = []

var done_init: bool = false
func do_init():
	await get_tree().physics_frame
	# Create @x values (Time axis)
	var x: Array = [0]
	#var y1: Array = [0]
	#var y2: Array = [0]
	#var y3: Array = [0]
	#var y4: Array = [0]
	#var y5: Array = [0]
	#var y6: Array = [0]
	var y_axes: Array[Array] = []
	for i in graphed_components.size():
		y_axes.append([0])
	
	# Customize the chart properties
	var cp: ChartProperties = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.show_legend = true
	cp.title = graph_title
	cp.x_label = x_label
	cp.y_label = y_label
	cp.x_scale = 6
	cp.y_scale = 5
	cp.interactive = true  # Enables tooltips and click interactions
	cp.max_samples = max_samples
	cp.draw_origin = true
	
	for i in graphed_components.size():
		var new_func = Function.new(
			x, y_axes[i], graphed_components[i]+" "+graphed_component_metrics[i],
			{
				color = graphed_component_colors[i], # Red
				marker = Function.Marker.NONE,
				type = Function.Type.LINE,
				interpolation = Function.Interpolation.LINEAR
			}
		)
		component_functions.append(new_func)
	
			#color = Color("#ff0000"), # Red
			#marker = Function.Marker.NONE,
			#type = Function.Type.LINE,
			#interpolation = Function.Interpolation.LINEAR
			#color = Color("#ffcc00"), # Yellow
			#marker = Function.Marker.NONE,
			#type = Function.Type.LINE,
			#interpolation = Function.Interpolation.LINEAR
			#color = Color("#0088ff"), # Blue
			#marker = Function.Marker.NONE,
			#type = Function.Type.LINE,
			#interpolation = Function.Interpolation.LINEAR
			#color = Color("#00cc66"), # Green
			#marker = Function.Marker.NONE,
			#type = Function.Type.LINE,
			#interpolation = Function.Interpolation.LINEAR
			#color = Color("#888888"), # Grey
			#marker = Function.Marker.NONE,
			#type = Function.Type.LINE,
			#interpolation = Function.Interpolation.LINEAR
			#color = Color("#ffa500"), # Orange
			#marker = Function.Marker.NONE,
			#type = Function.Type.LINE,
			#interpolation = Function.Interpolation.LINEAR

	
	# Plot all datasets
	chart.plot(component_functions, cp)

	# Uncomment to enable real-time updating
	set_process(true)
	done_init = true

var curr_x: float = 0.0
var update_graph_elapsed := 1.0
var update_graph_interval := 1.0
func _process(delta: float):
	if not done_init:
		return
	# This function updates the values dynamically for real-time graphing
	update_graph_elapsed += delta
	
	if update_graph_elapsed >= update_graph_interval:
		curr_x += 1.0
		update_graph_elapsed = 0.0
		for i in component_functions.size():
			var curr_func = component_functions[i]
			var data = MQTTHandler.get_component_metric(graphed_components[i], graphed_component_metrics[i])
			var curr_y = 0.0
			if data is Dictionary and data != null:
				curr_y = data.value
			curr_func.add_point(curr_x, curr_y)
		
		chart.queue_redraw()  # Forces the chart to refresh
