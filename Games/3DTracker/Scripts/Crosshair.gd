extends TextureRect

var target_position = Vector2()

var on_target = false
var current_scale = 1.5
var min_scale = 0.6
var max_scale = 1.5
var shrink_speed = 3.0
var grow_speed = 2.0

var reset_timer = 0.0
var reset_duration = 1  # time before it can lock again

func _ready():
	rect_pivot_offset = rect_size / 2

func set_target(pos):
	target_position = pos

func set_on_target(value):
	on_target = value
	

func is_fully_locked():
	return on_target and current_scale <= min_scale + 0.01 and reset_timer <= 0
	
func trigger_reset():
	on_target = false
	reset_timer = reset_duration

func _process(delta):
	#print(current_scale)
	# Smooth movement
	#rect_position = rect_position.linear_interpolate(target_position, 0.2)
	rect_position = rect_position.linear_interpolate(
	target_position - rect_size / 2,
	0.2
)

	# 🎯 Scale logic
	if reset_timer > 0:
		reset_timer -= delta
		on_target = false  # force unlock during reset
	
	if on_target:
		current_scale -= shrink_speed * delta
	else:
		current_scale += grow_speed * delta

	current_scale = clamp(current_scale, min_scale, max_scale)
	rect_scale = Vector2(current_scale, current_scale)
