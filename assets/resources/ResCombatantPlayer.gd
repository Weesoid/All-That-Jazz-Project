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
var initialized = false

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	if EQUIPMENT['armor'] != null:
		CombatGlobals.addStatusEffect(self, EQUIPMENT['armor'].STATUS_EFFECT)
		print(EQUIPMENT['armor'].STATUS_EFFECT.afflicted_combatant.getStatusBar().get_children())
	if EQUIPMENT['charm'] != null:
		CombatGlobals.addStatusEffect(self, EQUIPMENT['charm'].STATUS_EFFECT)
	
	if !initialized:
		SCENE.get_node("EnergyBarComponent").max_value = STAT_VALUES['verve']
		SCENE.get_node("EnergyBarComponent").value = STAT_VALUES['verve']
		SCENE.get_node("HealthBarComponent").max_value = STAT_VALUES['health']
		SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		initialized = true
	else:
		SCENE.get_node("EnergyBarComponent").max_value = BASE_STAT_VALUES['verve']
		SCENE.get_node("EnergyBarComponent").value = STAT_VALUES['verve']
		
		SCENE.get_node("HealthBarComponent").max_value = BASE_STAT_VALUES['health']
		SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
		
	for effect in STATUS_EFFECTS:
		effect.initializeStatus()

func act():
	player_turn.emit()
	
