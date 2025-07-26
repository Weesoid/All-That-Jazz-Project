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

@export var name: String
@export_multiline var description: String
@export var icon: Texture = preload("res://images/ability_icons/default.png")
@export var animation: PackedScene
@export var basic_effects: Array[ResAbilityEffect]
@export var ability_script: GDScript = preload("res://scripts/combat/abilities/scaBasicAbility.gd")
@export var target_type: TargetType
@export var target_group: TargetGroup
@export var required_effect: Dictionary = {'status_effect': null, 'rank': 0}
@export var charges: int = 0
@export var can_target_self: bool = false
@export var can_target_dead: bool = false
@export var dead_target_params = {'only_dead':false, 'only_faded': true}
@export var caster_position: Dictionary = {'min':0, 'max':3}
@export var target_position: Dictionary = {'min':0, 'max':3}
@export var tension_cost: int = 0
@export var instant_cast: bool = false
@export var required_level = 0

var current_effect: ResAbilityEffect
var current_charge: int
var enabled: bool = true

signal single_target(type)
signal multi_target(type)
signal random_target(type)

func execute():
	match target_type:
		TargetType.SINGLE: single_target.emit(self, 1)
		TargetType.MULTI: multi_target.emit(self, 2)

func getValidTargets(combatants: Array[ResCombatant], is_caster_player: bool):
	combatants = combatants.filter(func(combatant: ResCombatant): return is_instance_valid(combatant.combatant_scene))
	if target_group == TargetGroup.SELF:
		return CombatGlobals.getCombatScene().active_combatant
	if !can_target_dead:
		combatants = combatants.filter(func(combatant): return !combatant.isDead())
	if !can_target_self:
		combatants.erase(CombatGlobals.getCombatScene().active_combatant)
	if target_group == TargetGroup.ALLIES or target_group == TargetGroup.ENEMIES:
		combatants = combatants.filter(func(combatant): return isCombatantInRange(combatant, 'target'))
	if dead_target_params['only_dead']:
		combatants = combatants.filter(func(combatant): return combatant.isDead())
	if dead_target_params['only_faded']:
		combatants = combatants.filter(func(combatant): return (combatant.isDead() and combatant.hasStatusEffect('Fading') or !combatant.isDead()))
	
	if is_caster_player:
		match target_group:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ENEMIES: 
				if combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResEnemyCombatant).size() > 0 and target_type == TargetType.SINGLE:
					combatants = combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResEnemyCombatant)
				return combatants.filter(func isEnemy(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ALL: return combatants
	else:
		match target_group:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ENEMIES: 
				if combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResPlayerCombatant).size() > 0 and target_type == TargetType.SINGLE:
					combatants = combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting') and combatant is ResPlayerCombatant)
				return combatants.filter(func isEnemy(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ALL: return combatants

func canUse(caster: ResCombatant, targets=null):
	if caster is ResPlayerCombatant and CombatGlobals.tension < tension_cost:
		return false
	if required_effect['status_effect'] != null and !(caster.hasStatusEffect(required_effect['status_effect'].name) and caster.getStatusEffect(required_effect['status_effect'].name).current_rank >= required_effect['rank']):
		return false
	if charges > 0:
		return CombatGlobals.getCombatScene().getChargesLeft(caster, self) > 0
	
	if targets == null or targets is ResCombatant:
		return isCombatantInRange(caster, 'caster')
	else:
		var valid_targets = getValidTargets(targets, caster is ResPlayerCombatant)
		return isCombatantInRange(caster, 'caster') and ((valid_targets is Array and !valid_targets.is_empty()) or (valid_targets is ResCombatant))

func isCombatantInRange(combatant: ResCombatant, target_range: String):
	var position = CombatGlobals.getCombatScene().getCombatantPosition(combatant)
	if target_range == 'caster':
		return position >= caster_position['min'] and position <= caster_position['max']
	elif target_range == 'target':
		return position >= target_position['min'] and position <= target_position['max']

func getCost():
#	for i in range(21):
#		print(i, ' = ', str(snappedf(100 * pow(i, 0.25), 10)))
	return snappedf(100 * pow(required_level, 0.25), 10)

func getTargetType():
	match target_type:
		TargetType.SINGLE: return CombatScene.TargetState.SINGLE
		TargetType.MULTI: return CombatScene.TargetState.MULTI

func _to_string():
	return name

func getRichDescription(with_name=true)-> String:
	var rich_description = ''
	if with_name:
		rich_description += name.to_upper()+'\n'
	rich_description += getPositionIcon()
	if tension_cost > 0:
		rich_description += '	[img]res://images/sprites/icon_tp.png[/img] %s' % tension_cost
	#description += '[img]%s[/img]' % [getValidTargetIcon()]
	if instant_cast:
		rich_description += '	[img]%s[/img]' % "res://images/sprites/icon_fast_cast.png"
	rich_description += '\n '+ description
	if charges > 0 and !OverworldGlobals.inCombat():
		rich_description += '[color=yellow] Uses: '+str(charges)
	return rich_description

func getValidTargetIcon():
	if target_group == TargetGroup.SELF:
		return "res://images/sprites/icon_single_friend.png"
	if target_type == TargetType.SINGLE:
		match target_group:
			TargetGroup.ALLIES: return "res://images/sprites/icon_single_friend.png"
			TargetGroup.ENEMIES:  return "res://images/sprites/icon_single_enemy.png"
			TargetGroup.ALL: return "res://images/sprites/icon_single_all.png"
	if target_type == TargetType.MULTI:
		match target_group:
			TargetGroup.ALLIES: return "res://images/sprites/icon_multi_friend.png"
			TargetGroup.ENEMIES:  return "res://images/sprites/icon_multi_enemy.png"
			TargetGroup.ALL: return "res://images/sprites/icon_multi_all.png"

func getPositionIcon(ignore_active_pos:bool=false, is_enemy:bool=false)-> String:
	var valid = "res://images/sprites/circle_self.png"
	var valid_self = "res://images/sprites/circle_self_pos.png"
	var invalid_self = "res://images/sprites/circle_self_pos_invalid.png"
	var valid_ally = "res://images/sprites/circle_ally.png"
	var valid_enemy = "res://images/sprites/circle_enemy.png"
	var invalid = "res://images/sprites/circle_invalid.png"
	var postions = []
	
	for i in range(3, -1, -1):
		if i >= caster_position['min'] and i <= caster_position['max']:
			if CombatGlobals.inCombat() and i == CombatGlobals.getCombatScene().getCombatantPosition() and !ignore_active_pos:
				postions.append(valid_self)
			else:
				postions.append(valid)
		elif CombatGlobals.inCombat() and i == CombatGlobals.getCombatScene().getCombatantPosition() and !ignore_active_pos:
			postions.append(invalid_self)
		else:
			postions.append(invalid)
	
	if target_group != TargetGroup.SELF:
		if target_group == TargetGroup.ENEMIES:
#			if is_enemy:
#				invalid =  "res://images/sprites/circle_enemy.png"
#				valid_enemy = "res://images/sprites/circle_invalid.png"
			for j in range(4):
				if j >= target_position['min'] and j <= target_position['max']:
					postions.append(valid_enemy)
				else:
					postions.append(invalid)
		else:
#			if is_enemy:
#				invalid =   "res://images/sprites/circle_ally.png"
#				valid_ally = "res://images/sprites/circle_invalid.png"
			for i in range(3, -1, -1):
				if i >= caster_position['min'] and i <= caster_position['max']:
					postions.append(valid_ally)
				else:
					postions.append(invalid)
	if is_enemy:
		postions.reverse()
	
	if target_group != TargetGroup.SELF:
		return '[img]%s[/img][img]%s[/img][img]%s[/img][img]%s[/img] [img]%s[/img][img]%s[/img][img]%s[/img][img]%s[/img]' % postions
	else:
		return '[img]%s[/img][img]%s[/img][img]%s[/img][img]%s[/img]' % postions

func isBasicAbility():
	return basic_effects.size() > 0

func isOnslaught():
	for effect in basic_effects:
		if effect is ResOnslaughtEffect: return true
	
	return false
