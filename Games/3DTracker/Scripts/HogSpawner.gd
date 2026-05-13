extends Node

export(PackedScene) var HogScene
#export var spawn_count = 10
export var spawn_distance = 10.0
export var spawn_radius = 25.0

onready var camera = get_node("../MainCamera")

func _ready():
	call_deferred("spawn_hogs")


func spawn_hogs():
	#Random hogs 10-20
	var spawn_count = randi() % 11 + 10

	var forward = -camera.global_transform.basis.z
	var right = camera.global_transform.basis.x

	var center = Vector3(
		(camera.global_transform.origin.x),
		0,
		(camera.global_transform.origin.z) - 30
		)

	for i in range(spawn_count):

		var hog = HogScene.instance()
		get_tree().current_scene.add_child(hog)

		call_deferred("position_hog", hog, center, right)
		

func position_hog(hog, center, right):

	var angle = rand_range(0, PI * 2)
	var radius = rand_range(0, spawn_radius)

	var dir = Vector3(
		cos(angle),
		0,
		sin(angle)
	)

	var pos = center + dir * radius

	hog.global_transform.origin = pos
