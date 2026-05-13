extends Control

func _on_BackButton_pressed():
	get_tree().change_scene("res://Scenes/TitleScreen.tscn")


func _on_CameraButton_pressed():
		#path to green_tracker.py
	var script_path = "/home/nano/GodotGames/green_tracker.py"
	
	Globals.use_mouse = false
	OS.execute("/usr/bin/python3", [script_path], false)
	
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://Scenes/World.tscn")


func _on_MouseButton_pressed():
	Globals.use_mouse = true
	get_tree().change_scene("res://Scenes/World.tscn")
