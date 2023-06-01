extends ResCombatant
class_name ResPlayerCombatant

var initalized = false

func initializeCombatant():
	SCENE = load(str("res://assets/combatant_sprites_scenes/",SPRITE_NAME,".tscn")).instantiate()
	if !initalized:
		for ability in ABILITY_SET:
			ability.initializeAbility()
		
		SCENE.get_node("EnergyBarComponent").max_value = STAT_VALUES['verve']
		SCENE.get_node("EnergyBarComponent").value = STAT_VALUES['verve']
		SCENE.get_node("HealthBarComponent").max_value = STAT_VALUES['health']
		SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		initalized = true
	else:
		SCENE.get_node("EnergyBarComponent").max_value = BASE_STAT_VALUES['verve']
		SCENE.get_node("EnergyBarComponent").value = STAT_VALUES['verve']
		
		SCENE.get_node("HealthBarComponent").max_value = BASE_STAT_VALUES['health']
		SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
		
func act():
	player_turn.emit()
