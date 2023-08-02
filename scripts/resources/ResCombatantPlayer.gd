extends ResCombatant
class_name ResPlayerCombatant

@export var STAT_GROWTH_RATES = {
	'health': 1,
	'verve': 1,
	'hustle': 1,
	'brawn': 1,
	'wit': 1,
	'grit': 1,
	'will': 1
}
@export var FOLLOWER_PACKED_SCENE: PackedScene

var FOLLOWER_SCENE
var initialized = false

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	if FOLLOWER_PACKED_SCENE != null:
		FOLLOWER_SCENE = FOLLOWER_PACKED_SCENE.instantiate()
	
	if EQUIPMENT['armor'] != null and EQUIPMENT['armor'].STATUS_EFFECT != null:
		CombatGlobals.addStatusEffect(self, EQUIPMENT['armor'].STATUS_EFFECT)
	if EQUIPMENT['charm'] != null:
		CombatGlobals.addStatusEffect(self, EQUIPMENT['charm'].STATUS_EFFECT)
	
	if !initialized:
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		initialized = true
	
	for effect in STATUS_EFFECTS:
		effect.initializeStatus()

func act():
	player_turn.emit()
	
