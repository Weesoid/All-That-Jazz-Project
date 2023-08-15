# Refactor Exstensions
extends Resource
class_name ResCombatant

## Backend export variables
@export var NAME: String
@export var PACKED_SCENE: PackedScene
@export var DESCRIPTION: String

## Frontend / Gameplay export variables
@export var STAT_VALUES = {
	'health': 100,
	'verve': 8,
	'hustle': 1,
	'brawn': 1,
	'wit': 1,
	'grit': 1,
	'will': 1,
	'crit': 0.05,
	'accuracy': 0.95,
	'heal mult': 1,
	'exposure': 0
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

func getMaxHealth():
	return BASE_STAT_VALUES['health']

func getStatusEffect(stat_name: String)-> ResStatusEffect:
	print(STATUS_EFFECTS)
	for status in STATUS_EFFECTS:
		print('CHECKING: ', status.NAME)
		if status.NAME == stat_name:
			print('Returning')
			return status
	
	return null

func isDead()-> bool:
	return STAT_VALUES['health'] <= 0
	
func getStringStats():
	var result = ""
	for key in BASE_STAT_VALUES.keys():
		if key == 'health':
			result += key.to_upper() + ": " + str(STAT_VALUES[key]) + ' / ' + str(BASE_STAT_VALUES[key]) + "\n"
		else:
			result += key.to_upper() + ": " + str(BASE_STAT_VALUES[key]) + "\n"
	return result

	
func _to_string():
	return str(NAME)
