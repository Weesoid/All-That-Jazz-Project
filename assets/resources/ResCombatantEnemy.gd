extends ResCombatant
class_name ResEnemyCombatant

@export var COUNT: int = 1
@export var AI_PACKAGE: GDScript
@export var DROPS = {}

func initializeCombatant():
	SCENE = load(str("res://assets/combatant_sprites_scenes/",SPRITE_NAME,".tscn")).instantiate()
	
	for ability in ABILITY_SET:
		ability.initializeAbility()
	
	for effect in STATUS_EFFECTS:
		effect.initializeStatus()
	
	SCENE.get_node("EnergyBarComponent").hide()
	
	SCENE.get_node("HealthBarComponent").max_value = STAT_VALUES['health']
	SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
	BASE_STAT_VALUES = STAT_VALUES.duplicate()

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
