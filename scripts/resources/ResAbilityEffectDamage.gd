## Basically the "Attack" action. Requires a caster to execute.
extends ResAbilityEffect
class_name ResAttackEffect

enum DamageType {
	MELEE,
	RANGED,
	RANGED_PIERCING
}

## Animation the caster will do.
@export var damage_type: DamageType
@export var attack_bonuses: Array[ResAttackBonus]
@export var damage_modifier: float = 1.0
## Additional stats to be applied on usage.
## Conditions:
## 		hp = Health threshold ex. crit/hp:>:0.5 or crit/hp:<:0.75
## 		s = Status effect ex. crit/s:bleed
##		combo =  Only execute if target has combo token. Combo token is consumed. ex. crit/combo:0.75
##			combo! = The same as combo but it will not consume the combo token. ex. crit/combo!:0.75
##		% = Chance to trigger. ex. crit/%:0.5
## 	Special stats:
##		status_effect = Apply status effect ex. "status_effect": "Poison" (Must use file sys name) 
##			"Poison+Riposte" Will add an array of status effects
##			"status_effect": "Poison^{"duration":6,"be_<identifier>":{"damange",9}}" Will override status effects properties
##		move = Move the target combatant. e.g. "move": "f,1" (Means forward one space) (b,2 would mean backward 2 spaces)
var bonus_stats: Dictionary={}
## Only applicable if damage type is "Custom". What animation the caster will do.
@export var cast_animation: Dictionary= {'animation': '', 'go_to_target': false} 
@export var can_miss: bool = true
@export var can_crit: bool = true
@export var return_pos: bool = true
@export var plant_self_on_combo: bool
@export var indicator_bb:  String = ''
var do_not_return_pos: bool=false

func initializeAttackBonuses():
	for bonus in attack_bonuses:
		bonus_stats.merge(bonus.getAttackEffect())

func getAttackBonuses(target:ResCombatant):
	var out = {}
	
	for attack_bonus in attack_bonuses:
		if !attack_bonus.conditionsPassed(target): continue
		
		out = CombatGlobals.combineDictionaries(out,attack_bonus.getAttackEffect())
		#if attack_bonus is ResAttackStats:
		#elif attack_bonus is ResAttackStatusEffect:
		#	out = CombatGlobals.combineDictionaries(out,attack_bonus.getEffects())
	
	return out 

func _to_string():
	var out=''
	
	out += stringifyCondition()
	if is_combo_effect:
		out += 'On [img]res://images/status_icons/icon_combo.png[/img]:\n'
	if damage_type == DamageType.MELEE or cast_animation['animation'].to_lower().contains('melee'):
		out += "[img]res://images/sprites/icon_melee.png[/img] "
	elif (damage_type == DamageType.RANGED or damage_type == DamageType.RANGED_PIERCING) or cast_animation['animation'].to_lower().contains('ranged'):
		out += "[img]res://images/sprites/icon_range.png[/img] "
	
	if damage_modifier > 1.0 or damage_modifier < 1.0:
		var sign
		if damage_modifier > 1.0:
			sign = SettingsGlobals.ui_colors['up-bb']+'+[/color]'
		elif damage_modifier < 1.0:
			sign = SettingsGlobals.ui_colors['down-bb']+'-[/color]'
		out += sign+SettingsGlobals.colorValueBB(damage_modifier*100,100.0)+'%[/color]\n'
	else:
		out += '\n'
	
#	var i = 1
#	for key in bonus_stats.keys():
#		var bonus_stat_str = key.split('/')[0]
#		if CombatGlobals.hasStatCondition(key):
#			out += CombatGlobals.stringifyBonusStatConditions(key.split('/'))+' '
#
#		if bonus_stats[key] is float:
#			out += SettingsGlobals.colorValueBB(bonus_stats[key]*100,0)+'% '+bonus_stat_str.to_upper()+'[/color]'
#		elif bonus_stats[key] is int:
#			out += SettingsGlobals.colorValueBB(bonus_stats[key],0)+' '+bonus_stat_str.to_upper()+'[/color]'
#		elif bonus_stats[key] is String:
#			out += CombatGlobals.stringifySpecialStat(bonus_stat_str, bonus_stats[key])
#		if i != bonus_stats.size():
#			out += '\n'
#
#		i += 1
	
	return out
