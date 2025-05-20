# Refactor Exstensions
extends Resource
class_name ResCombatant

## Backend export variables
@export var NAME: String
@export var PACKED_SCENE: PackedScene
@export var DESCRIPTION: String

## Frontend / Gameplay export variables
@export var STAT_VALUES = {
	'health': 20,
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
@export var SCALE_STATS: Dictionary = {
	'health': true,
	'brawn': true,
	'grit': true,
	'handling': false,
	'hustle': true,
	'accuracy': false,
	'crit': false,
	'crit_dmg': false,
	'heal_mult': false,
	'resist': false
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
var pos_tween: Tween
var scale_tween: Tween

signal enemy_turn
signal player_turn

func initializeCombatant():
	pass

func resetSprite():
	getSprite().position = Vector2.ZERO
	getSprite().scale = Vector2(1.0,1.0)

func startBreatheTween(await_start:bool):
	if await_start:
		randomize()
		await CombatGlobals.get_tree().create_timer(randf_range(0.0,1.0)).timeout
	if self is ResEnemyCombatant and self.is_converted:
		setBreatheTween(1)
	else:
		setBreatheTween(0)

func stopBreatheTween():
	if scale_tween == null or pos_tween == null:
		return
	
	scale_tween.stop()
	pos_tween.stop()
	resetSprite()

func setBreatheTween(mode:int):
	if is_instance_valid(SCENE) and scale_tween == null and pos_tween == null:
		scale_tween = SCENE.create_tween().set_loops()
		pos_tween = SCENE.create_tween().set_loops()
		#resetSprite()
	elif is_instance_valid(SCENE) and !scale_tween.is_running() and !pos_tween.is_running() and scale_tween != null and pos_tween != null:
		#getAnimator().play('RESET')
		scale_tween.play()
		pos_tween.play()
		return
	else:
		return
	getSprite().position = Vector2.ZERO
	match mode:
		0: # Normal Breathing
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.05), 1.5)
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,-1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,0.0), 1.5)
		1: # Inverted Breathing (For converted enemies)
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.05), 1.5)
			scale_tween.tween_property(getSprite(), "scale", Vector2(1.0,1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,1.0), 1.5)
			pos_tween.tween_property(getSprite(), "position", Vector2(0.0,0.0), 1.5)

func act():
	pass

func scaleStats():
	var stat_increase = {}
	for stat in STAT_VALUES.keys():
		if SCALE_STATS[stat]: 
			stat_increase[stat] = (BASE_STAT_VALUES[stat] * (1 + ((PlayerGlobals.PARTY_LEVEL-1)*0.1))) - BASE_STAT_VALUES[stat]
#		if (stat == 'health' or  stat == 'hustle') and BASE_STAT_VALUES[stat]:
#			stat_increase[stat] = int(stat_increase[stat])
	CombatGlobals.modifyStat(self, stat_increase, 'scaled_stats')

func getSprite()-> Sprite2D:
	return SCENE.get_node('Sprite2D')

func getAnimator()-> AnimationPlayer:
	return SCENE.get_node('AnimationPlayer')

func getStatusEffectNames()-> Array[String]:
	var names: Array[String] = []
	for effect in STATUS_EFFECTS:
		names.append(effect.NAME)
	return names

# On-hit = 1, Get hit = 2
func removeStatusEffect(remove_type: int):
	for effect in STATUS_EFFECTS:
		if effect.REMOVE_WHEN == remove_type: 
			match effect.REMOVE_STYLE:
				0: effect.removeStatusEffect()
				1: effect.tick(false, true)

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

func isImmobilized()-> bool:
	return STAT_VALUES['hustle'] < -99 and !hasStatusEffect('Fading')

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
