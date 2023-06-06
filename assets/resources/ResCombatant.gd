# Refactor Exstensions
extends Resource
class_name ResCombatant

## Backend export variables
@export var NAME: String
@export var SPRITE_NAME: String
@export var DESCRIPTION: String

## Frontend / Gameplay export variables
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
@export var EQUIPMENT = {
	'weapon': null,
	'armor': null,
	'charm': null
}
var STATUS_EFFECTS: Array[ResStatusEffect]
var BASE_STAT_VALUES: Dictionary
var SCENE

signal enemy_turn
signal player_turn

func initializeCombatant():
	pass
	
func act():
	pass
	
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
	
func updateHealth(new_health):
	SCENE.get_node("HealthBarComponent").value = new_health
	
func updateEnergy(new_energy):
	SCENE.get_node("EnergyBarComponent").value = new_energy
	
func getMaxHealth():
	return SCENE.get_node("HealthBarComponent").max_value
	
func isDead()-> bool:
	return STAT_VALUES['health'] < 0
	
func getStringStats():
	var result = ""
	for key in BASE_STAT_VALUES.keys():
		result += key.to_upper() + ": " + str(BASE_STAT_VALUES[key]) + "\n"
	return result

	
func _to_string():
	return str(NAME)
