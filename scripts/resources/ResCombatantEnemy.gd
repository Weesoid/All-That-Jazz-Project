extends ResCombatant
class_name ResEnemyCombatant

@export var COUNT: int = 1
@export var AI_PACKAGE: GDScript
@export var DROPS = {}

# NOTE: Enemy combatants don't get the stat modifications of their gear.
# They do get the ARMOR TYPE and STATUS EFFECTS on armors and charms
# Set the auto-attack manually.
func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	for effect in STATUS_EFFECTS:
		effect.initializeStatus()
	
	BASE_STAT_VALUES = STAT_VALUES.duplicate()
	
	if isEquipped('armor'):
		if EQUIPMENT['armor'].STATUS_EFFECT != null:
			var status_effect = EQUIPMENT['armor'].STATUS_EFFECT.duplicate()
			CombatGlobals.addStatusEffect(self, status_effect)

func act():
	enemy_turn.emit()

func selectTarget(combatant_array: Array[ResCombatant])-> ResCombatant:
	return AI_PACKAGE.selectTarget(combatant_array)

func getExperience():
	var out = 0
	for key in BASE_STAT_VALUES.keys():
		if key == "health": continue
		out += BASE_STAT_VALUES[key]
	return out

func getDrops():
	var total_weight = 0
	var cum_weight = 0
	
	for weight in DROPS.values():
		total_weight += weight
	
	var random_num = randf_range(0,total_weight)
	for drop in DROPS:
		cum_weight += DROPS[drop]
		if random_num <= cum_weight: return drop
