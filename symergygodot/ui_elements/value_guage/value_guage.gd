extends AspectRatioContainer

@export var balanced_value: float = 0.0
@export var value_min: float = 0.0
@export var value_max: float = 0.0
@export var update_interval: float = 0.05
@export var unit: String = ""
@onready var update_elapsed: float = update_interval
var current_value: float = 1.23456789: 
	set(value):
		current_value = clamp(value, value_min, value_max)

const max_rot_angle: float = 135.0
@onready var guage_needle = $GaugeNeedle

@export var testing_mode: bool = false

@onready var start_size: Vector2 = Vector2(250.0, 250.0)
func _ready() -> void:
	set_needle_offset()

func set_needle_offset():
	var new_ratio: float = guage_needle.size.x/start_size.x
	guage_needle.pivot_offset = guage_needle.size/2.0
	guage_needle.pivot_offset.x += 4.5*new_ratio
	guage_needle.pivot_offset.y -= 1.0*new_ratio
	$GaugeBody/Label.add_theme_font_size_override("font_size", 32*new_ratio)

func set_current_value(new_value: float):
	current_value = new_value
	set_needle_offset()
	var rounded_val = "%.2f" % (new_value)
	$GaugeBody/Label.text = rounded_val+" "+unit

var time: float = 0.0
var target_angle = 0.0
func _physics_process(delta: float) -> void:
	if testing_mode:
		time += delta
		var mid_value = (value_min + value_max) / 2.0
		var amplitude = (value_max - value_min) / 2.0
		current_value = mid_value + amplitude * sin(2*time)
	
	update_elapsed += delta
	if update_elapsed >= update_interval and current_value != 1.23456789:
		update_elapsed = 0.0
		# Normalize current_value to range [-1, 1] based on left and right max
		var normalized_value = inverse_lerp(value_min, value_max, current_value) * 2.0 - 1.0
		
		# Interpolate rotation angle based on normalized value
		target_angle = max_rot_angle * normalized_value
		
	# Smoothly interpolate rotation
	guage_needle.rotation_degrees = lerpf(guage_needle.rotation_degrees, target_angle, 5.0*delta)
