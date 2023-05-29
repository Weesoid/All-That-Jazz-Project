extends Resource
class_name ResCombatant

enum ArmorType {
	NEUTRAL,
	LIGHT,
	HEAVY
}

## Backend export variables
@export var NAME: String
@export var SPRITE_NAME: String
@export var IS_PLAYER_UNIT: bool
@export var COUNT: int = 1
@export var AI_PACKAGE_NAME: String

## Frontend / Gameplay export variables
@export var ARMOR_TYPE: ArmorType
@export var STAT_VALUES = {
	'health': 1,
	'verve': 1,
	'hustle': 1,
	'brawn': 1,
	'wit': 1,
	'grit': 1,
	'will': 1
}
@export var ABILITY_SET: Array[ResAbility] # May need to be refactored to dict for specific selection

var STATUS_EFFECTS: Array[ResStatusEffect]
var BASE_STAT_VALUES
var SCENE
var AI_PACKAGE

signal enemy_turn
signal player_turn

func initializeCombatant():
	SCENE = load(str("res://assets/combatant_sprites_scenes/",SPRITE_NAME,".tscn")).instantiate()
	for ability in ABILITY_SET:
		ability.initializeAbility()
	if !IS_PLAYER_UNIT:
		AI_PACKAGE = load(str("res://assets/ai_scripts/",AI_PACKAGE_NAME,".gd"))
		SCENE.get_node("EnergyBarComponent").hide()
	else:
		SCENE.get_node("EnergyBarComponent").max_value = STAT_VALUES['verve']
		SCENE.get_node("EnergyBarComponent").value = STAT_VALUES['verve']
	
	SCENE.get_node("HealthBarComponent").max_value = STAT_VALUES['health']
	SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
	BASE_STAT_VALUES = STAT_VALUES.duplicate()
	
func act():
	if IS_PLAYER_UNIT:
		player_turn.emit()
	else:
		enemy_turn.emit()
	
func getSprite()-> Sprite2D:
	return SCENE.get_node('Sprite')
	
func playIndicator(value):
	SCENE.get_node("IndicatorComponent").text = str(value)
	SCENE.get_node("IndicatorComponent").get_node("Animator").play('Show')
	
func getAnimator()-> AnimationPlayer:
	return getSprite().get_node('SpriteAnimator')
	
func getStatusBar():
	return SCENE.get_node("StatusBarComponent")
	
func getStatusEffectNames():
	var names = []
	for effect in STATUS_EFFECTS:
		names.append(effect.NAME)
	return names
	
func selectTarget(combatant_array: Array[ResCombatant])-> ResCombatant:
	return AI_PACKAGE.selectTarget(combatant_array)
	
func updateHealth(new_health):
	SCENE.get_node("HealthBarComponent").value = new_health
	
func updateEnergy(new_energy):
	SCENE.get_node("EnergyBarComponent").value = new_energy
	
func getMaxHealth():
	return SCENE.get_node("HealthBarComponent").max_value
	
func isDead()-> bool:
	return STAT_VALUES['health'] < 0
	
func _to_string():
	return str(NAME)
