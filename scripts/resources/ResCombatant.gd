# Refactor Exstensions
extends Resource
class_name ResCombatant

## Backend export variables
@export var NAME: String
@export var PACKED_SCENE: PackedScene
@export var DESCRIPTION: String

## Frontend / Gameplay export variables
@export var STAT_VALUES = {
	'health': 25,
	'brawn': 0.0,
	'grit': 0.0,
	'handling': 0,
	'hustle': 1,
	'accuracy': 0.95,
	'crit': 0.05,
	'crit_dmg': 1.5,
	'heal_mult': 1.0,
	'resist': 0.05
}
@export var ABILITY_SET: Array[ResAbility] # May need to be refactored to dict for specific selection
@export var MAX_TURN_CHARGES = 1
@export var AI_PACKAGE: GDScript
var TURN_CHARGES: int
var STAT_MODIFIERS = {}
var STATUS_EFFECTS: Array[ResStatusEffect]
var LINGERING_STATUS_EFFECTS: Array[String]
var BASE_STAT_VALUES: Dictionary
var ROLLED_SPEED: int
var ACTED: bool
var SCENE: CombatantScene

signal enemy_turn
signal player_turn

func initializeCombatant():
	pass

func act():
	pass

func getSprite()-> Sprite2D:
	return SCENE.get_node('Sprite2D')

func getAnimator()-> AnimationPlayer:
	return SCENE.get_node('AnimationPlayer')

func getStatusEffectNames():
	var names = []
	for effect in STATUS_EFFECTS:
		names.append(effect.NAME)
	return names

func getMaxHealth():
	return BASE_STAT_VALUES['health']

func getStatusEffect(stat_name: String)-> ResStatusEffect:
	for status in STATUS_EFFECTS:
		if status.NAME == stat_name:
			return status
	
	return null

func hasStatusEffect(stat_name: String)-> bool:
	for status in STATUS_EFFECTS:
		if status.NAME == stat_name:
			return true
	
	return false

func isDead()-> bool:
	return STAT_VALUES['health'] < 1.0

func getStringStats(current_stats=false):
	var result = ""
	var stats
	if current_stats:
		stats = BASE_STAT_VALUES
	else:
		stats = STAT_VALUES
	
	for key in stats:
		if key == 'health':
			result += key.to_upper() + ": " + str(int(STAT_VALUES[key])) + ' / ' + str(BASE_STAT_VALUES[key]) + "\n"
		elif BASE_STAT_VALUES[key] is float:
			result += key.to_upper() + ": " + str(BASE_STAT_VALUES[key]*100) + "%\n"
		else:
			result += key.to_upper() + ": " + str(BASE_STAT_VALUES[key]) + "\n"
	return result

# NOT USED YET, MIGHT BE USED LATER
func searchStringStats(stats: Array[String]):
	var result = ""
	for key in BASE_STAT_VALUES.keys():
		if stats.has(key):
			if key == 'health':
				result += key.to_upper() + ": " + str(int(STAT_VALUES[key])) + ' / ' + str(BASE_STAT_VALUES[key]) + "\n"
			else:
				result += key.to_upper() + ": " + str(BASE_STAT_VALUES[key]) + "\n"
	return result

func applyStatModifications(modifier_id: String):
	for modifier in STAT_MODIFIERS.keys():
		if modifier == modifier_id:
			for stat in STAT_MODIFIERS[modifier]:
				if stat == 'health':
					updateHealth(STAT_MODIFIERS[modifier][stat])
				else:
					STAT_VALUES[stat] += STAT_MODIFIERS[modifier][stat]
			return

func removeStatModification(modifier_id: String):
	for modifier in STAT_MODIFIERS.keys():
		if modifier == modifier_id:
			for stat in STAT_MODIFIERS[modifier]:
				if stat == 'health':
					updateHealth(-STAT_MODIFIERS[modifier][stat])
				else:
					STAT_VALUES[stat] -= STAT_MODIFIERS[modifier][stat]
			STAT_MODIFIERS.erase(modifier)
			return

func updateHealth(amount: int):
	var percent_health = float(STAT_VALUES['health']) / float(BASE_STAT_VALUES['health'])
	BASE_STAT_VALUES['health'] += amount
	if STAT_VALUES['health'] >= BASE_STAT_VALUES['health'] or percent_health == 1:
		STAT_VALUES['health'] = BASE_STAT_VALUES['health']

func _to_string():
	return str(NAME)
