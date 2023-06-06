extends ResCombatant
class_name ResEnemyCombatant

@export var COUNT: int = 1
@export var AI_PACKAGE: GDScript

func initializeCombatant():
	SCENE = load(str("res://assets/combatant_sprites_scenes/",SPRITE_NAME,".tscn")).instantiate()
	for ability in ABILITY_SET:
		ability.initializeAbility()
	
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
		if key != "health":
			out += BASE_STAT_VALUES[key]
	return out
