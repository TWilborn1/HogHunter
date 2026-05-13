extends Node

var udp := PacketPeerUDP.new()

onready var crosshair = $"../CanvasLayer/Crosshair"
onready var camera = $"../MainCamera"   

const CAMERA_WIDTH = 640
const CAMERA_HEIGHT = 480

var center_offset = Vector2(320, 240)
var sensitivity = 3.5
var deadzone = 10

var can_shoot = true
var shoot_cooldown = 0.5
var shoot_timer = 0.0

# aim tracking
var last_hit = null
var current_screen_pos = Vector2()

# bullet
var BulletScene = preload("res://Scenes/Bullet.tscn")

# gun
var GunScene = preload("res://Scenes/ShotgunV1.tscn")
var gun = null
var muzzle = null
var muzzle_flash = null

func _ready():
	udp.listen(4242)
	
	gun = GunScene.instance()
	camera.add_child(gun)
	gun.translation = Vector3(0.3, -1.0, -1.2)
	
	muzzle = gun.get_node("Muzzle")
	muzzle_flash = gun.get_node("MuzzleFlash")

func _process(delta):

	# -------------------------
	# COOLDOWN
	# -------------------------
	if !can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
			shoot_timer = 0

	var use_mouse = Globals.use_mouse

	# -------------------------
	# MOUSE AIM
	# -------------------------
	if use_mouse:
		var mouse_pos = get_viewport().get_mouse_position()
		current_screen_pos = mouse_pos
		crosshair.set_target(mouse_pos)
		shoot_ray(mouse_pos)

	# -------------------------
	# CAMERA AIM (UDP)
	# -------------------------
	else:
		while udp.get_available_packet_count() > 0:
			var msg = udp.get_packet().get_string_from_utf8()
			var parts = msg.split(",")

			if parts.size() == 2:
				var x = float(parts[0])
				var y = float(parts[1])
				
				var screen_size = get_viewport().size
				
				var screen_pos = Vector2(x, y)
				
				var dx = x - screen_size.x / 2
				var dy = y - screen_size.y / 2
				if abs(dx) < deadzone:
					screen_pos.x = screen_size.x / 2
				if abs(dy) < deadzone:
					screen_pos.y = screen_size.y / 2
				
				screen_pos.x = clamp(screen_pos.x, 0, screen_size.x)
				screen_pos.y = clamp(screen_pos.y, 0, screen_size.y)
				
				current_screen_pos = screen_pos
				crosshair.set_target(screen_pos)
				shoot_ray(screen_pos)

	# -------------------------
	# FIRE BULLET WHEN LOCKED
	# -------------------------
	if crosshair.is_fully_locked() and can_shoot:
		fire_bullet()
		crosshair.trigger_reset()
		can_shoot = false
		shoot_timer = shoot_cooldown
		
	update_gun_aim()

# Gun points to Crosshair
func update_gun_aim():
	if gun == null:
		print("Gun null")
		return

	var origin = camera.global_transform.origin
	var dir = camera.project_ray_normal(current_screen_pos)

	var target_pos = origin + dir * 10.0

	gun.look_at(target_pos, Vector3.UP)
	gun.rotate_y(deg2rad(90))

# -------------------------
# FIRE BULLET
# -------------------------
func fire_bullet():
	if muzzle == null:
		print("No muzzle found!")
		return

	var from = muzzle.global_transform.origin
	var dir = camera.project_ray_normal(current_screen_pos)

	var bullet = BulletScene.instance()
	get_tree().current_scene.add_child(bullet)

	bullet.global_transform.origin = from
	bullet.direction = dir.normalized()
	
	play_muzzle_flash()

# Muzzle Flash
func play_muzzle_flash():
	if muzzle_flash == null:
		print("null flash")
		return

	muzzle_flash.visible = true
	muzzle_flash.scale = Vector3.ONE * rand_range(0.8, 1.2)
	muzzle_flash.rotation_degrees.z = rand_range(0, 360)

	var particles = muzzle_flash.get_node_or_null("CPUParticles")
	if particles:
		particles.restart()

	yield(get_tree().create_timer(0.05), "timeout")
	muzzle_flash.visible = false

# -------------------------
# RAYCAST (AIM ASSIST ONLY)
# -------------------------
func shoot_ray(screen_pos):
	var offsets = [
		Vector2(0, 0),
		Vector2(5, 0), Vector2(-5, 0),
		Vector2(0, 5), Vector2(0, -5)
	]

	var space_state = camera.get_world().direct_space_state
	var hit_hog = false

	for offset in offsets:
		var pos = screen_pos + offset
		var from = camera.project_ray_origin(pos)
		var to = from + camera.project_ray_normal(pos) * 1000
		var result = space_state.intersect_ray(from, to)

		if result and result.collider.is_in_group("hog"):
			hit_hog = true
			break

	crosshair.set_on_target(hit_hog)
