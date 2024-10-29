extends Resource
class_name ResAbility

enum TargetType {
	SINGLE,
	MULTI
}

enum TargetGroup {
	ALLIES,
	ENEMIES,
	SELF,
	ALL
}

@export var NAME: String
@export var DESCRIPTION: String
@export var ANIMATION: PackedScene
@export var BASIC_EFFECTS: Array[ResAbilityEffect]
@export var ABILITY_SCRIPT: GDScript = preload("res://scripts/combat/abilities/scaBasicAbility.gd")
@export var TARGET_TYPE: TargetType
@export var TARGET_GROUP: TargetGroup
@export var CAN_TARGET_SELF: bool = false
@export var TARGET_DEAD: bool = false
@export var CASTER_POSITION: Dictionary = {'min':0, 'max':3}
@export var TARGET_POSITION: Dictionary = {'min':0, 'max':3}
@export var TENSION_COST: int = 0
@export var INSTANT_CAST: bool = false
@export var REQUIRED_LEVEL = 0

var current_effect: ResAbilityEffect
var ENABLED: bool = true
var TARGETABLE

signal single_target(type)
signal multi_target(type)
signal random_target(type)

func execute():
	match TARGET_TYPE:
		TargetType.SINGLE: single_target.emit(self, 1)
		TargetType.MULTI: multi_target.emit(self, 2)

func getValidTargets(combatants: Array[ResCombatant], is_caster_player: bool):
	combatants = combatants.filter(func(combatant: ResCombatant): return is_instance_valid(combatant.SCENE))
	if TARGET_GROUP == TargetGroup.SELF:
		return CombatGlobals.getCombatScene().active_combatant
	if !TARGET_DEAD:
		combatants = combatants.filter(func(combatant): return !combatant.isDead())
	if !CAN_TARGET_SELF:
		combatants.erase(CombatGlobals.getCombatScene().active_combatant)
	if TARGET_GROUP == TargetGroup.ALLIES or TARGET_GROUP == TargetGroup.ENEMIES:
		combatants = combatants.filter(func(combatant): return isCombatantInRange(combatant, 'target'))
	for combatant in combatants:
		if combatant.isDead() and !combatant.hasStatusEffect('Fading'): combatants.erase(combatant)
	
	if is_caster_player:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ENEMIES: 
				if combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResEnemyCombatant).size() > 0 and TARGET_TYPE == TargetType.SINGLE:
					combatants = combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResEnemyCombatant)
				return combatants.filter(func isEnemy(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ALL: return combatants
	else:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ENEMIES: 
				if combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResPlayerCombatant).size() > 0 and TARGET_TYPE == TargetType.SINGLE:
					combatants = combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResPlayerCombatant)
				return combatants.filter(func isEnemy(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ALL: return combatants

func canUse(caster: ResCombatant, targets=null):
	if caster is ResPlayerCombatant and CombatGlobals.TENSION < TENSION_COST:
		return false
	if targets == null or targets is ResCombatant:
		return isCombatantInRange(caster, 'caster')
	else:
		var valid_targets = getValidTargets(targets, caster is ResPlayerCombatant)
		return isCombatantInRange(caster, 'caster') and ((valid_targets is Array and !valid_targets.is_empty()) or (valid_targets is ResCombatant))

func isCombatantInRange(combatant: ResCombatant, target_range: String):
	var position = CombatGlobals.getCombatScene().getCombatantPosition(combatant)
	if target_range == 'caster':
		return position >= CASTER_POSITION['min'] and position <= CASTER_POSITION['max']
	elif target_range == 'target':
		return position >= TARGET_POSITION['min'] and position <= TARGET_POSITION['max']

func getTargetType():
	match TARGET_TYPE:
		TargetType.SINGLE: return 1
		TargetType.MULTI: return 2

func _to_string():
	return NAME

func getRichDescription(with_name=true)-> String:
	var description = ''
	if with_name:
		description += NAME.to_upper()+'\n'
	description += getPositionIcon()
	if TENSION_COST > 0:
		description += '	[img]res://images/sprites/icon_tp.png[/img] %s' % TENSION_COST
	#description += '[img]%s[/img]' % [getValidTargetIcon()]
	if INSTANT_CAST:
		description += '[img]%s[/img]' % "res://images/sprites/icon_fast_cast.png"
	description += '\n '+DESCRIPTION
	return description

func getValidTargetIcon():
	if TARGET_GROUP == TargetGroup.SELF:
		return "res://images/sprites/icon_single_friend.png"
	if TARGET_TYPE == TargetType.SINGLE:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return "res://images/sprites/icon_single_friend.png"
			TargetGroup.ENEMIES:  return "res://images/sprites/icon_single_enemy.png"
			TargetGroup.ALL: return "res://images/sprites/icon_single_all.png"
	if TARGET_TYPE == TargetType.MULTI:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return "res://images/sprites/icon_multi_friend.png"
			TargetGroup.ENEMIES:  return "res://images/sprites/icon_multi_enemy.png"
			TargetGroup.ALL: return "res://images/sprites/icon_multi_all.png"

func getPositionIcon()-> String:
	var valid = "res://images/sprites/circle_self.png"
	var valid_self = "res://images/sprites/circle_self_pos.png"
	var valid_ally = "res://images/sprites/circle_ally.png"
	var valid_enemy = "res://images/sprites/circle_enemy.png"
	var invalid = "res://images/sprites/circle_invalid.png"
	var postions = []
	for i in range(3, -1, -1):
		if i >= CASTER_POSITION['min'] and i <= CASTER_POSITION['max']:
			if CombatGlobals.inCombat() and i == CombatGlobals.getCombatScene().getCombatantPosition():
				postions.append(valid_self)
			else:
				postions.append(valid)
		else:
			postions.append(invalid)
	
	if TARGET_GROUP != TargetGroup.SELF:
		if TARGET_GROUP == TargetGroup.ENEMIES:
			for j in range(4):
				if j >= TARGET_POSITION['min'] and j <= TARGET_POSITION['max']:
					postions.append(valid_enemy)
				else:
					postions.append(invalid)
		else:
			for i in range(3, -1, -1):
				if i >= CASTER_POSITION['min'] and i <= CASTER_POSITION['max']:
					postions.append(valid_ally)
				else:
					postions.append(invalid)
	
	if TARGET_GROUP != TargetGroup.SELF:
		return '[img]%s[/img][img]%s[/img][img]%s[/img][img]%s[/img] [img]%s[/img][img]%s[/img][img]%s[/img][img]%s[/img]' % postions
	else:
		return '[img]%s[/img][img]%s[/img][img]%s[/img][img]%s[/img]' % postions
