extends CenterContainer

@export var balanced_value: float = 0.0
@export var left_value_max: float = -1.0
@export var right_value_max: float = 1.0
@export var update_interval: float = 0.05
@onready var update_elapsed: float = update_interval
var current_value: float = 0.0

const max_rot_angle: float = 18.3
@onready var teeter_arm = $AspectRatioContainer/TeeterArm

@export var testing_mode: bool = false

var time: float = 0.0
func _physics_process(delta: float) -> void:
	if testing_mode:
		time += delta
		var mid_value = (left_value_max + right_value_max) / 2.0
		var amplitude = (right_value_max - left_value_max) / 2.0
		current_value = mid_value + amplitude * sin(2*time)
	
	update_elapsed += delta
	if update_elapsed >= update_interval:
		update_elapsed = 0.0
		# Normalize current_value to range [-1, 1] based on left and right max
		var normalized_value = inverse_lerp(left_value_max, right_value_max, current_value) * 2.0 - 1.0
		
		# Interpolate rotation angle based on normalized value
		var target_angle = max_rot_angle * normalized_value
		
		# Smoothly interpolate rotation
		teeter_arm.rotation_degrees = lerp(teeter_arm.rotation_degrees, target_angle, delta * 10.0)
