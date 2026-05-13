extends Button

export var script_path: String = "/home/nano/GodotGames/launch_game.sh"

func _ready():
	grab_focus()

func _pressed():
	print ("launch_game.sh activated Full Path: " + script_path)
	OS.execute(script_path, ["MainMenuV2.pck"], false)
	get_tree().quit()
