extends RichTextLabel

@onready var animator = $AnimationPlayer
@onready var timer = $Timer
@onready var audio_player = $AudioStreamPlayer

func _process(_delta):
	if OverworldGlobals.showing_menu:
		modulate.a = 0.25
	else:
		modulate.a = 1.0
	
func animatePrompt(action: int):
	match action:
		1: 
			animator.play("Show")
		0: 
			animator.play_backwards("Show")
			await animator.animation_finished
			text = ''

func showPrompt(message: String, time=5.0, audio_file = ''):
	if text.is_empty():
		text += ' '+message
		animatePrompt(1)
		timer.start(time)
	else:
		text += '\n '+message
		timer.start(timer.time_left + 0.5)
	
	if !audio_file.is_empty():
		audio_player.stream = load("res://assets/sounds/%s" % audio_file)
		audio_player.play()
	
	if get_line_count() > 10:
		timer.timeout.emit()

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_clear_prompts"):
		timer.timeout.emit()

func _on_timer_timeout():
	animatePrompt(0)
	timer.stop()
