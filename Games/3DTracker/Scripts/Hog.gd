extends KinematicBody

var speed = 2.0

var target_position = Vector3.ZERO
var velocity = Vector3.ZERO

var wait_time = 0.0
var is_waiting = false

var gravity = -10

onready var anim = $animal_hog/AnimationPlayer

var health = 20

var is_running = false
var run_time = 0.0
var run_duration = 2.0
var normal_speed = 2.0
var run_speed = 5.0

func _ready():

	randomize()

	var scale_factor = rand_range(1, 1.5)
	scale = Vector3(scale_factor, scale_factor, scale_factor)

	if anim.has_animation("walk"):
		anim.get_animation("walk").loop = true
	if anim.has_animation("run"):
		anim.get_animation("run").loop = true

	add_to_group("hog")
	pick_new_target()
	start_wait()


func _physics_process(delta):
	#Running movement
	if is_running:
		run_time -= delta
		if run_time <= 0:
			is_running = false
			speed = normal_speed

	#Static Movement
	if is_waiting:
		wait_time -= delta

		velocity.x = 0
		velocity.z = 0

		apply_gravity(delta)
		velocity = move_and_slide(velocity, Vector3.UP)

		if wait_time <= 0:
			is_waiting = false
			pick_new_target()

		update_anim()
		return


	apply_gravity(delta)

	#General Movement
	var direction = target_position - global_transform.origin
	direction.y = 0

	if direction.length() < 0.8:
		start_wait()
		velocity.x = 0
		velocity.z = 0
		velocity = move_and_slide(velocity, Vector3.UP)
		update_anim()
		return
	else:
		direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	velocity = move_and_slide(velocity, Vector3.UP)
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()

	if horizontal_speed < 0.1 and not is_waiting and not is_running:
		start_wait()

	#Turning
	if direction != Vector3.ZERO:
		var target_angle = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 3 * delta)


	update_anim()
	
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func start_wait():
	is_waiting = true
	wait_time = rand_range(0.5, 2.0)

func pick_new_target():

	var angle = rand_range(0, PI * 2)
	var distance = rand_range(5.0, 12.0)

	var dir = Vector3(cos(angle), 0, sin(angle)).normalized()

	target_position = global_transform.origin + dir * distance

func update_anim():

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()

	if is_running:
		play_anim("run")
	elif is_waiting or horizontal_speed < 0.2:
		play_anim("static")
	else:
		play_anim("walk")

func play_anim(name):
	if anim and anim.has_animation(name) and anim.current_animation != name:
		anim.play(name)

func hit():
	take_damage(10)

func take_damage(amount):
	print("Hog took damage")
	health -= amount

	var world = get_tree().current_scene
	if world and world.has_method("show_damage_marker"):
		world.show_damage_marker(amount)

	# 🔥 trigger run behavior
	is_running = true
	run_time = run_duration
	speed = run_speed

	pick_new_target()

	if health <= 0:
		die()

func die():
	var world = get_tree().current_scene

	if world.has_method("add_score"):
		world.add_score(1)

	queue_free()
	call_deferred("_request_replacement")

func _request_replacement():
	var world = get_tree().current_scene
	if world and world.has_method("replace_target"):
		world.replace_target()
