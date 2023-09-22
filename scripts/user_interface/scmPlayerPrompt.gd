extends RichTextLabel

@onready var animator = $AnimationPlayer

var showing = false

func animatePrompt(action: int):
	match action:
		1: 
			animator.play("Show")
			showing = true
		0: 
			animator.play_backwards("Show")
			showing = false
			await animator.animation_finished
			text = ''

func showPrompt(message: String, time=5.0):
	if !showing:
		text += ' '+message
		animatePrompt(1)
		await get_tree().create_timer(time).timeout
		animatePrompt(0)
	else:
		text += '\n '+message
