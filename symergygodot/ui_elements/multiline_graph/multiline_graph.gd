extends Control

@onready var chart: Chart = $Chart
@export var max_samples: int = 60
@onready var connected: bool = false

# Plot these functions
var f_gen: Function
var f_solar: Function
var f_wind: Function
var f_hydro: Function
var f_load_total: Function
var f_source_total: Function

func _ready():
	await get_tree().process_frame
	
	# Create @x values (Time axis)
	var x: Array = [0]
	var y1: Array = [0]
	var y2: Array = [0]
	var y3: Array = [0]
	var y4: Array = [0]
	var y5: Array = [0]
	var y6: Array = [0]
	
	# Customize the chart properties
	var cp: ChartProperties = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.show_legend = true
	cp.title = "Power Output Over Time"
	cp.x_label = "Time (s)"
	cp.y_label = "Power Output (kW)"
	cp.x_scale = 6
	cp.y_scale = 5
	cp.interactive = true  # Enables tooltips and click interactions
	cp.max_samples = max_samples
	cp.draw_origin = true
	
	# Create function objects for each dataset
	f_gen = Function.new(
		x, y1, "Generator",
		{ 
			color = Color("#ff0000"), # Red
			marker = Function.Marker.NONE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	f_solar = Function.new(
		x, y2, "Solar",
		{ 
			color = Color("#ffcc00"), # Yellow
			marker = Function.Marker.NONE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	f_wind = Function.new(
		x, y3, "Wind",
		{ 
			color = Color("#0088ff"), # Blue
			marker = Function.Marker.NONE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	f_hydro = Function.new(
		x, y4, "Hydro",
		{ 
			color = Color("#00cc66"), # Green
			marker = Function.Marker.NONE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	f_load_total = Function.new(
		x, y5, "Total Load",
		{ 
			color = Color("#888888"), # Grey
			marker = Function.Marker.NONE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	f_source_total = Function.new(
		x, y6, "Total Source",
		{ 
			color = Color("#ffa500"), # Orange
			marker = Function.Marker.NONE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	# Plot all datasets
	chart.plot([f_gen, f_solar, f_wind, f_hydro, f_load_total, f_source_total], cp)

	# Uncomment to enable real-time updating
	set_process(true)

func set_curr_power(power: float, category: String):
	match category:
		"generator":
			curr_gen_power = power
		"solar":
			curr_solar_power = power
		"wind":
			curr_wind_power = power
		"hydro":
			curr_hydro_power = power
		"total_load":
			curr_load_power = power
		"total_source":
			curr_source_power = power

var curr_gen_power = 0.0
var curr_solar_power = 0.0
var curr_wind_power = 0.0
var curr_hydro_power = 0.0
var curr_load_power = 0.0
var curr_source_power = 0.0

var curr_x: float = 0.0
var update_graph_elapsed := 1.0
var update_graph_interval := 1.0
func _process(delta: float):
	# This function updates the values dynamically for real-time graphing
	update_graph_elapsed += delta
	
	if update_graph_elapsed >= update_graph_interval and connected:
		curr_x += 1.0
		update_graph_elapsed = 0.0
		f_gen.add_point(curr_x, curr_gen_power)
		f_solar.add_point(curr_x, curr_solar_power)
		f_wind.add_point(curr_x, curr_wind_power)
		f_hydro.add_point(curr_x, curr_hydro_power)
		f_load_total.add_point(curr_x, curr_load_power)
		f_source_total.add_point(curr_x, curr_source_power)
		
		chart.queue_redraw()  # Forces the chart to refresh
