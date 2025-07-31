extends RichTextLabel

@onready var animator = $AnimationPlayer
@onready var timer = $Timer
@onready var audio_player = $AudioStreamPlayer
var prompts = {}


func _process(_delta):
	if prompts.size() > 100:
		prompts.clear()
	
	for key in prompts.keys():
		if !animator.is_playing():
			text = prompts[key][0]
			if !prompts[key][2].is_empty():
				audio_player.stream = load("res://audio/sounds/%s" % prompts[key][2])
				audio_player.play()
			
			animatePrompt(1)
			await animator.animation_finished
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
	for msg in prompts.values():
		if msg[0] == message: return
	
	prompts[message] = [message, time, audio_file]

func _on_timer_timeout():
	animatePrompt(0)
	timer.stop()
