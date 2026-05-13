extends Spatial

export var game_time := 30.0

onready var score_label = $CanvasLayer/ScoreButton/Score
onready var timer_label = $CanvasLayer/TimerButton/Timer
onready var pause_button = $CanvasLayer/Pause
onready var pause_overlay = $CanvasLayer/PauseOverlay
onready var damage_marker = $CanvasLayer/DamageMarker

var score := 0
var time_left := 0.0
var game_over := false
var is_paused := false

func _ready():
	randomize()
	score = 0
	time_left = game_time
	game_over = false
	is_paused = false
	update_score_label()
	update_timer_label()
	pause_overlay.visible = false
	damage_marker.visible = false

func _process(delta):
	if game_over or is_paused:
		return

	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		update_timer_label()
		end_game()
		return

	update_timer_label()

func add_score(points):
	if game_over:
		return

	score += points
	update_score_label()

func update_score_label():
	score_label.text = "Score: " + str(score)

func update_timer_label():
	timer_label.text = "Time: " + str(int(ceil(time_left)))

func end_game():
	if game_over:
		return

	game_over = true
	get_tree().paused = false
	Globals.final_score = score
	get_tree().change_scene("res://Scenes/GameOver.tscn")

func pause_game():
	if game_over:
		return

	is_paused = true
	pause_overlay.visible = true
	get_tree().paused = true

func resume_game():
	get_tree().paused = false
	is_paused = false
	pause_overlay.visible = false

func _on_Resume_pressed():
	resume_game()
	
func _on_Quit_pressed():
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene("res://Scenes/TitleScreen.tscn")
	
func show_damage_marker(amount):
	damage_marker.visible = true
	damage_marker.text = "HOG WOUNDED! -" + str(amount) + " HEALTH"

	var timer = Timer.new()
	timer.wait_time = 0.4
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", self, "_hide_damage_marker", [timer])
	timer.start()

func _hide_damage_marker(timer):
	damage_marker.visible = false
	timer.queue_free()
	
	


func _on_PauseButton_pressed():
	if is_paused:
		resume_game()
	else:
		pause_game()
