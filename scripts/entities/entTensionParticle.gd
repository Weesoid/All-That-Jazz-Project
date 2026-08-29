extends Node2D
class_name TensionParticle

@onready var animator = $AnimationPlayer
signal finished
var is_burnout:bool=false
#func _ready():
#	#print('gago ka')
#	#CombatGlobals.getCombatScene().moveCamera(global_position)
#	print('spawned globby: ', global_position)
#	expulse()

func _ready():
	modulate = SettingsGlobals.ui_colors['up']
	if !is_burnout:
		var rotate_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		rotate_tween.tween_property(self,'rotation', randf_range(-4,4),1.25)

func expulse(combatant: CombatantScene):
	var direction = 1 if combatant.combatant_resource is ResPlayerCombatant else -1
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)#.set_parallel()
	var rand_y = randf_range(-16, 16)
	global_position = combatant.global_position
	tween.tween_property(self,'global_position', global_position+(Vector2(-48*direction,rand_y)),0.2)
	tween.tween_interval(0.33)
	await tween.finished
	if !is_burnout:
		attract()
	else:
		OverworldGlobals.playSound("res://audio/sounds/831929__1bob__flamethrower.ogg")
		animator.play("Burn")
		var linger_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		linger_tween.tween_property(self,'global_position', global_position+Vector2(0,-16),1)
		await linger_tween.finished
		queue_free()

func attract():
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel().set_ease(Tween.EASE_IN_OUT)
	var magnet_pos = CombatGlobals.getCombatScene().tension_magnet.global_position
	tween.tween_property(self,'global_position', magnet_pos,0.1)
	tween.tween_property(self, 'self_modulate', Color.TRANSPARENT,0.09)
	await tween.finished
	OverworldGlobals.playSound("res://audio/sounds/27_sword_miss_3.ogg")
	finished.emit()
	queue_free()
