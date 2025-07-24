extends Node2D

@onready var experience = $ProgressBar
@onready var label = $ProgressBar/Label
@onready var animator = $AnimationPlayer
var added_exp: int

func _ready():
	var tween = create_tween()
	animator.play('Show')
	experience.max_value = PlayerGlobals.getRequiredExp()
	experience.value = PlayerGlobals.current_exp
	tween.tween_property(experience, 'value', experience.value+added_exp,0.5)
	await tween.finished
	if experience.value >= experience.max_value:
		if PlayerGlobals.max_team_level <= PlayerGlobals.team_level:
			label.text = 'Max!'
		else:
			label.text = 'Lvl Up!'
		var color_tween = create_tween()
		color_tween.tween_property(self, 'modulate', Color.YELLOW, 0.25)
		color_tween.tween_property(self, 'modulate', Color.WHITE, 1.25)
		OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
	await get_tree().create_timer(2.0).timeout
	animator.play_backwards('Show')
	await animator.animation_finished
	queue_free()
