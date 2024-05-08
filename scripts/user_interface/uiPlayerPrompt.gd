extends RichTextLabel

@onready var animator = $AnimationPlayer
@onready var timer = $Timer
@onready var audio_player = $AudioStreamPlayer
var prompts = {}


func _process(_delta):
	if prompts.size() > 100:
		print('Clearing prompts!')
		prompts.clear()
	
	for key in prompts.keys():
		if !animator.is_playing():
			text = prompts[key][0]
			if !prompts[key][2].is_empty():
				audio_player.stream = load("res://audio/sounds/%s" % prompts[key][2])
				audio_player.play()
			
			animatePrompt(1)
			await  animator.animation_finished
			prompts.erase(key)

func animatePrompt(action: int):
	match action:
		1: 
			animator.play("Show")
		0: 
			animator.play_backwards("Show")
			await animator.animation_finished
			text = ''

func showPrompt(message: String, time=5.0, audio_file = ''):
	prompts[prompts.size()] = [message, time, audio_file]

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
