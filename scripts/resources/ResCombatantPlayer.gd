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
@export var ABILITY_POOL: Array[ResAbility]
@export var FOLLOWER_PACKED_SCENE: PackedScene
@export var MANDATORY = false
var LINGERING_STATUS_EFFECTS: Array[String]
var UNMODIFIED_STAT_VALUES: Dictionary
var ABILITY_POINTS = 0
var initialized = false
var active = false

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	if !initialized:
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		UNMODIFIED_STAT_VALUES = STAT_VALUES.duplicate()
		initialized = true
	
	applyStatusEffects()

func act():
	player_turn.emit()

func applyStatusEffects():
	if isEquipped('armor'):
		if EQUIPMENT['armor'].STATUS_EFFECT != null:
			CombatGlobals.addStatusEffect(self, EQUIPMENT['armor'].STATUS_EFFECT.NAME)
	for charm in CHARMS:
		if charm == null: continue
		if charm.STATUS_EFFECT != null:
			CombatGlobals.addStatusEffect(self, charm.STATUS_EFFECT.NAME)
	for effect in LINGERING_STATUS_EFFECTS:
		print(LINGERING_STATUS_EFFECTS)
		CombatGlobals.addStatusEffect(self, effect)

func applyEquipmentModifications():
	for item in EQUIPMENT.values():
		if item != null:
			item.applyStatModifications()
	for charm in CHARMS:
			charm.applyStatModifications()

func removeEquipmentModifications():
	for item in EQUIPMENT.values():
		if item != null:
			item.removeStatModifications()
	for charm in CHARMS:
			charm.removeStatModifications()

func updateStatValues(previous_max_health, previous_max_verve):
	STAT_VALUES['health'] =  BASE_STAT_VALUES['health'] * (float(STAT_VALUES['health']) / float(previous_max_health))
	STAT_VALUES['verve'] =  BASE_STAT_VALUES['verve'] * (float(STAT_VALUES['verve']) / float(previous_max_verve))
	for stat in BASE_STAT_VALUES.keys():
		if stat == 'health' or stat == 'verve': continue
		STAT_VALUES[stat] = BASE_STAT_VALUES[stat]
