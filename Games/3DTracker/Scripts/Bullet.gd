extends Area

export var speed = 250.0
var direction = Vector3.ZERO

func _process(delta):
	direction = direction.normalized()
	
	var move_distance = speed * delta
	
	# cast a ray before moving to catch anything we might tunnel through
	var space_state = get_world().direct_space_state
	var from = global_transform.origin
	var to = from + direction * move_distance

	var result = space_state.intersect_ray(from, to, [self])
	
	if result:
		# hit something
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(10)
		queue_free()
		return
	
	# nothing hit so move normally
	global_translate(direction * move_distance)

func _on_Bullet_body_entered(last_hit):
	if last_hit.has_method("hit"):
		last_hit.take_damage(10)
	queue_free()

func _on_Bullet_area_entered(area):
	if area.has_method("hit"):
		area.take_damage(10)
	queue_free()

func _on_Timer_timeout():
	queue_free()
