extends Node2D
class_name AnimationPulse

@onready var sprite = $Sprite2D

func showAnimation(radius:float, duration:float=0.4, color:Color=Color.WHITE):
#	var color: Color
#	match mode:
#		0: color=Color.DARK_GRAY
#		1: color=Color.ORANGE
#		2: color=Color.RED
#		3: color=Color.WHITE
	var calculated_scale = (0.00450612244898*radius)+0.000938775510204
	var scale_tween = get_tree().create_tween()
	var opacity_tween = get_tree().create_tween()
	scale_tween.tween_property(sprite, 'scale', Vector2(calculated_scale, calculated_scale), duration)
	opacity_tween.tween_property(sprite, 'modulate', Color(color,0.0), duration+0.025)
	await opacity_tween.finished
	queue_free()
