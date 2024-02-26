extends ResCombatant
class_name ResPlayerCombatant

@export var ABILITY_POOL: Array[ResAbility]
@export var FOLLOWER_PACKED_SCENE: PackedScene
@export var MANDATORY = false
var LINGERING_STATUS_EFFECTS: Array[String]
var STAT_POINTS = 0
var STAT_POINT_ALLOCATIONS = {
	'brawn': 0,
	'grit': 0,
	'handling': 0
}
var initialized = false
var active = false

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	if !initialized:
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		initialized = true
	
	applyStatusEffects()

func act():
	player_turn.emit()

func applyStatusEffects():
	for charm in CHARMS:
		if charm == null: continue
		if charm.STATUS_EFFECT != null:
			CombatGlobals.addStatusEffect(self, charm.STATUS_EFFECT.NAME)
	for effect in LINGERING_STATUS_EFFECTS:
		CombatGlobals.addStatusEffect(self, effect)

func applyEquipmentModifications():
	for charm in CHARMS:
		charm.applyStatModifications()

func removeEquipmentModifications():
	for charm in CHARMS:
		charm.removeStatModifications()

func updateStatValues(previous_max_health):
	STAT_VALUES['health'] =  BASE_STAT_VALUES['health'] * (float(STAT_VALUES['health']) / float(previous_max_health))
	for stat in BASE_STAT_VALUES.keys():
		if stat == 'health': continue
		STAT_VALUES[stat] = BASE_STAT_VALUES[stat]
