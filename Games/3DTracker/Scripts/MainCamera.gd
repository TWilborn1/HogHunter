extends Camera

onready var crosshair = $"../CanvasLayer/Crosshair"

func _process(delta):

	if Input.is_action_just_pressed("ui_accept"):  # press space/enter to test

		var screen_pos = crosshair.rect_global_position + crosshair.rect_size / 2

		var from = project_ray_origin(screen_pos)
		var to = from + project_ray_normal(screen_pos) * 1000

		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)

		if result:
			print("Hit object:", result.collider.name)
		else:
			print("No hit")
