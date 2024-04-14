extends RichTextLabel

@onready var animator = $AnimationPlayer
@onready var timer = $Timer
@onready var audio_player = $AudioStreamPlayer

#func _process(_delta):
#	if OverworldGlobals.inMenu():
#		visible = false
#	else:
#		visible = true
	
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
		audio_player.stream = load("res://audio/sounds/%s" % audio_file)
		audio_player.play()
	
	if get_line_count() > 6:
		timer.timeout.emit()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_clear_prompts"):
		var tween = create_tween()
		var pluh = OverworldGlobals.getPlayer()
		tween.tween_property(pluh, 'position', pluh.global_position + Vector2(20, 0), 0.25)
		tween.tween_property(pluh, 'position', pluh.global_position - Vector2(40, 0), 0.25)
		tween.tween_property(pluh, 'position', Vector2(0, 0), 0.25)

func _on_timer_timeout():
	animatePrompt(0)
	timer.stop()
