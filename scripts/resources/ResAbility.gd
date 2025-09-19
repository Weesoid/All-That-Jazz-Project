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
@export var mutation: Dictionary = {}

var current_effect: ResAbilityEffect
var current_charge: int
var enabled: bool = true
var default_properties:Dictionary={}

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
	return snappedf(100 * pow(required_level, 0.25), 10)

func getTargetType():
	match target_type:
		TargetType.SINGLE: return CombatScene.TargetState.SINGLE
		TargetType.MULTI: return CombatScene.TargetState.MULTI

func _to_string():
	return name

func getRichDescription(with_name=true)-> String:
	var rich_description = '[center]'
	if with_name:
		rich_description += name.to_upper()+'\n'
	rich_description += getPositionIcon()
	if tension_cost > 0:
		rich_description += '	[img]res://images/sprites/icon_tp.png[/img] %s' % tension_cost
	if instant_cast:
		rich_description += '	[img]%s[/img]' % "res://images/sprites/icon_fast_cast.png"
	if isBasicAbility():
		rich_description += '\n '+CombatGlobals.getBasicEffectsDescription(basic_effects)
	if description != '':
		rich_description += SettingsGlobals.bb_line
		rich_description += description
	if required_effect['status_effect'] != null:
		rich_description += SettingsGlobals.bb_line
		var effect = CombatGlobals.loadStatusEffect(required_effect['status_effect'].name)
		var rank = ''
		if required_effect['rank'] > 0:
			rank = effect.getIconColor(true)+str(required_effect['rank'])
		rich_description += '[color=yellow]Requires[/color] %s%s' % [rank, effect.getMessageIcon()]
	if charges > 0 and !OverworldGlobals.inCombat():
		rich_description += SettingsGlobals.bb_line
		rich_description += '[color=yellow] Uses: '+str(charges)
	return rich_description

func getPositionIcon(ignore_active_pos:bool=false, is_enemy:bool=false)-> String:
	var postions = []
	var invalid_self= setBBColor("res://images/sprites/circle_self_pos_invalid.png", 'color=white')
	var invalid = setBBColor("res://images/sprites/circle_invalid.png", 'color=white')
	var valid = setBBColor("res://images/sprites/circle_unit.png", SettingsGlobals.ui_colors['up-bb'])
	var valid_self = setBBColor("res://images/sprites/circle_self_pos.png", SettingsGlobals.ui_colors['up-bb'])
	var valid_ally
	var valid_enemy
	if target_type == TargetType.SINGLE:
		valid_ally = setBBColor("res://images/sprites/circle_unit.png", SettingsGlobals.ui_colors['up-bb'])
		valid_enemy = setBBColor("res://images/sprites/circle_unit.png", SettingsGlobals.ui_colors['down-bb'])
	else:
		valid_ally = setBBColor("res://images/sprites/circle_unit_link.png", SettingsGlobals.ui_colors['up-bb'])
		valid_enemy = setBBColor("res://images/sprites/circle_unit_link.png", SettingsGlobals.ui_colors['down-bb'])
	
	for i in range(3, -1, -1):
		if i >= caster_position['min'] and i <= caster_position['max']:
			if CombatGlobals.inCombat() and CombatGlobals.getCombatScene().active_combatant != null and i == CombatGlobals.getCombatScene().getCombatantPosition() and !ignore_active_pos:
				postions.append(valid_self)
			else:
				postions.append(valid)
		elif CombatGlobals.inCombat() and CombatGlobals.getCombatScene().active_combatant != null and i == CombatGlobals.getCombatScene().getCombatantPosition() and !ignore_active_pos:
			postions.append(invalid_self)
		else:
			postions.append(invalid)
	
	if target_group != TargetGroup.SELF:
		if target_group == TargetGroup.ENEMIES:
			for j in range(4):
				if j >= target_position['min'] and j <= target_position['max']:
					postions.append(valid_enemy)
				else:
					postions.append(invalid)
		else:
			for i in range(3, -1, -1):
				if i >= caster_position['min'] and i <= caster_position['max']:
					postions.append(valid_ally)
				else:
					postions.append(invalid)
	if is_enemy:
		postions.reverse()
	
	if target_group != TargetGroup.SELF:
		#print('%s%s%s%s %s%s%s%s' % postions)
		return '%s%s%s%s %s%s%s%s' % postions
	else:
		return '%s%s%s%s' % postions

func setBBColor(image_path:String, bb_color:String):
	return '[img %s]%s[/img]' % [bb_color.replace('[','').replace(']',''), image_path]

func isBasicAbility():
	return basic_effects.size() > 0

func isOnslaught():
	for effect in basic_effects:
		if effect is ResOnslaughtEffect: return true
	
	return false

func canMutate():
	return !mutation.is_empty()

func mutateProperties():
	if isMutated():
		return
	
	for property in mutation.keys():
		assert(get(property) != mutation[property], "Warning! %s property is the same as it's mutation." % property)
		
		if mutation[property] is Array:
			var array = []
			array.assign(get(property))
			default_properties[property] = array
			get(property).assign(mutation[property])
		else:
			default_properties[property] = get(property)
			set(property,mutation[property])

func restoreProperties():
	for property in default_properties.keys():
		if default_properties[property] is Array:
			get(property).assign(default_properties[property])
		else:
			set(property,default_properties[property])

func isMutated():
	var the_same = 0
	for property in mutation.keys():
		if get(property) == mutation[property]:
			the_same += 1
	
	return the_same == mutation.size()
