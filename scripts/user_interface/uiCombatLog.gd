extends Container

@onready var combat_log = $CombatLog
@onready var animator = $AnimationPlayer
@onready var timer = $Timer

func writeCombatLog(text: String, lifetime=5.0):	
	if !text.is_empty():
		combat_log.text = text
		timer.start(lifetime)
	animator.play("Show")
	
	await timer.timeout
	animator.play_backwards("Show")
	await animator.animation_finished
	combat_log.text = ''
