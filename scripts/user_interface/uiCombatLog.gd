extends PanelContainer

@onready var combat_log = $CombatLog
@onready var animator = $AnimationPlayer

func writeCombatLog(text: String, lifetime=5.0):
	combat_log.show()
	combat_log.text += '\n'+text
	animator.play("Show")
	await get_tree().create_timer(lifetime).timeout
	combat_log.text = ''
	if combat_log.visible:
		animator.play_backwards("Show")
	combat_log.hide()
