extends Control

export var script_path: String = "/home/nano/GodotGames/launch_game.sh"

func _on_StartButton_pressed():
	get_tree().change_scene("res://Scenes/InstructionsScreen.tscn")

func _on_QuitButton_pressed():
	print ("launch_game.sh activated Full Path: " + script_path)
	OS.execute(script_path, ["MainMenuV2.pck"], false)
	get_tree().quit()
