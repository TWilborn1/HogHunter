extends Control

onready var score_label = $FinalScoreLabel

func _ready():
	score_label.text = "Score: " + str(Globals.final_score)

func _on_RestartButton_pressed():
	get_tree().change_scene("res://Scenes/World.tscn")


func _on_QuitButton_pressed():
	get_tree().change_scene("res://Scenes/TitleScreen.tscn")
