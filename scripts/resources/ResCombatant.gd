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
	# Base Stats
	'health': 100,
	'brawn': 0.0,
	'grit': 0.0,
	'hustle': 1,
	# Hidden Stats
	'crit': 0.05,
	'dodge': 0.0,
	'accuracy': 0.95,
	'heal mult': 1.0,
	'exposure': 0.05
}
@export var ABILITY_SET: Array[ResAbility] # May need to be refactored to dict for specific selection
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
	
func getStatusEffectNames():
	var names = []
	for effect in STATUS_EFFECTS:
		names.append(effect.NAME)
	return names

func applyStatusEffects():
	for charm in CHARMS:
		if charm == null: continue
		if charm.STATUS_EFFECT != null:
			CombatGlobals.addStatusEffect(self, charm.STATUS_EFFECT.NAME)
	
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

func _to_string():
	return str(NAME)
