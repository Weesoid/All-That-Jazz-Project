extends Sprite2D
class_name PatrollerBubble

@onready var animator = $AnimationPlayer

func playBubbleAnimation(animation:String,sound:String):
	if !visible:
		visible = true
	if animator.current_animation != animation:
		OverworldGlobals.playSound2D(global_position, sound)
		animator.play(animation)
