extends ResCombatant
class_name ResPlayerCombatant

@export var STAT_GROWTH_RATES = {
	'health': 1,
	'verve': 1,
	'hustle': 1,
	'brawn': 1,
	'wit': 1,
	'grit': 1,
	'will': 1,
	'crit': 0,
	'accuracy': 0,
	'heal mult': 0,
	'exposure': 0
}
@export var ABILITY_POOL= {}
@export var FOLLOWER_PACKED_SCENE: PackedScene
@export var MANDATORY = false

var FOLLOWER_SCENE
var initialized = false
var active = false

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	if !initialized:
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		initialized = true
	
	if isEquipped('armor'):
		if EQUIPMENT['armor'].STATUS_EFFECT != null:
			var status_effect = EQUIPMENT['armor'].STATUS_EFFECT.duplicate()
			CombatGlobals.addStatusEffect(self, status_effect)

func act():
	player_turn.emit()
	
