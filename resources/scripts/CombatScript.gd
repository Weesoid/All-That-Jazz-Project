extends Node2D

@export var COMBATANTS: Array[Combatant] = []
var active_combatant: Combatant
var index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for c in COMBATANTS:
		c.init()
		c.player_turn.connect(on_player_turn)
		c.enemy_turn.connect(on_enemy_turn)
		if (c.IS_PLAYER_UNIT):
			$Interface/PlayerPanel/TeamContainer.add_child(c.SPRITE)
		else:
			$EnemyContainer.add_child(c.SPRITE)
	# COMBATANTS.sort_speed()
	print('Ready!')
	
	active_combatant = COMBATANTS[index]
	active_combatant.act()

func on_player_turn():
	$CombatLog.text = ""
	$DebugTimer.stop()
	$Interface/PlayerPanel.show()
	
func on_enemy_turn():
	$Interface/PlayerPanel.hide()
	$CombatLog.text = str(active_combatant.NAME, " does a FLIP!")
	active_combatant.SPRITE.flip_v = true
	$DebugTimer.start()
	

func end_turn():
	if (index + 1 < COMBATANTS.size()):
		index += 1
	else:
		index = 0
	
	active_combatant = COMBATANTS[index]
	active_combatant.act()

func _on_attack_pressed():
	end_turn()

func _on_debug_timer_timeout():
	print('end')
	active_combatant.SPRITE.flip_v = false
	end_turn()
