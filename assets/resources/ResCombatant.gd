# Refactor Exstensions
extends Resource
class_name ResCombatant

## Backend export variables
@export var NAME: String
@export var PACKED_SCENE: PackedScene
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
	
func getAnimator()-> AnimationPlayer:
	return getSprite().get_node('SpriteAnimator')
	
func getStatusBar():
	return SCENE.get_node("StatusBarComponent")
	
func getStatusEffectNames():
	var names = []
	for effect in STATUS_EFFECTS:
		names.append(effect.NAME)
	return names
	
func isEquipped(slot_name: String):
	return EQUIPMENT[slot_name] != null
	
func getEquipment(slot_name: String)-> ResEquippable:
	return EQUIPMENT[slot_name]

func updateHealth():
	SCENE.get_node("HealthBarComponent").value = STAT_VALUES['health']
	
func updateEnergy():
	SCENE.get_node("EnergyBarComponent").value = STAT_VALUES['verve']
	
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
