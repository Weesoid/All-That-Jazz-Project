# Refactor Exstensions
extends Resource
class_name ResCombatant

## Backend export variables
@export var NAME: String
@export var ICON: Texture
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
	'armor': null
}
@export var CHARMS: Array[ResCharm]
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

func applyStatusEffects():
	if isEquipped('armor'):
		if EQUIPMENT['armor'].STATUS_EFFECT != null:
			var status_effect = EQUIPMENT['armor'].STATUS_EFFECT.duplicate()
			CombatGlobals.addStatusEffect(self, status_effect)
	for charm in CHARMS:
		if charm == null: continue
		if charm.STATUS_EFFECT != null:
			var status_effect = charm.STATUS_EFFECT.duplicate()
			CombatGlobals.addStatusEffect(self, status_effect)

func getMaxHealth():
	return BASE_STAT_VALUES['health']

func getStatusEffect(stat_name: String)-> ResStatusEffect:
	for status in STATUS_EFFECTS:
		if status.NAME == stat_name:
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

# NOT USED YET, MIGHT BE USED LATER
func searchStringStats(stats: Array[String]):
	var result = ""
	for key in BASE_STAT_VALUES.keys():
		if stats.has(key):
			if key == 'health':
				result += key.to_upper() + ": " + str(STAT_VALUES[key]) + ' / ' + str(BASE_STAT_VALUES[key]) + "\n"
			else:
				result += key.to_upper() + ": " + str(BASE_STAT_VALUES[key]) + "\n"
	return result

func unequipGear():
	for equipment in EQUIPMENT.values():
		if equipment == null: continue
		equipment.unequip()

func getStringCurrentStats():
	var result = ""
	for key in STAT_VALUES.keys():
		if key == 'health':
			result += key.to_upper() + ": " + str(STAT_VALUES[key]) + ' / ' + str(BASE_STAT_VALUES[key]) + "\n"
		else:
			result += key.to_upper() + ": " + str(STAT_VALUES[key]) + "\n"
	return result

func getStringGear():
	var result = ""
	for key in EQUIPMENT.keys():
		result += key.to_upper() + ": " + str(EQUIPMENT[key]) + "\n"
	return result

func _to_string():
	return str(NAME)
