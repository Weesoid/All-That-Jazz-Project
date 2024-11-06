extends Container

@onready var combat_log = $CombatLog
@onready var animator = $AnimationPlayer

func writeCombatLog(text: String, lifetime=5.0):	
	if !text.is_empty(): combat_log.text = text
	animator.play("Show")
	await animator.animation_finished
	animator.play_backwards("Show")
	await animator.animation_finished
	combat_log.text = ''
