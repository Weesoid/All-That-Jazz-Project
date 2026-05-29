## Basically the "Attack" action. Requires a caster to execute.
extends ResAbilityEffect
class_name ResAttackEffect

enum DamageType {
	MELEE,
	RANGED,
	RANGED_PIERCING
}

@export var damage_type: DamageType
@export var attack_bonuses: Array[ResAttackBonus]
@export var damage_modifier: float = 1.0
@export var cast_animation: Dictionary= {'animation': '', 'go_to_target': false}
@export var can_miss: bool = true
@export var can_crit: bool = true
@export var return_pos: bool = true
@export var indicator_bb:  String = ''
@export var projectile_texture: Texture

func getAttackBonuses(target:ResCombatant):
	return getPassedAttackBonuses(target, attack_bonuses) 

static func getPassedAttackBonuses(target:ResCombatant, p_attack_bonuses: Array):
	var out = {}
	
	for attack_bonus in p_attack_bonuses:
		if attack_bonus == null or !attack_bonus.conditionsPassed(target): continue
		out = CombatGlobals.combineDictionaries(out,attack_bonus.getAttackEffect())
	
	return out 

func _to_string():
	var out=''
	
	#out += stringifyCondition()
#	if is_combo_effect:
#		out += 'On [img]res://images/status_icons/icon_combo.png[/img]:\n'
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
	
	for attack_bonus in attack_bonuses:
		if !attack_bonus.has_method('_to_string'): continue
		out += str(attack_bonus)
		if attack_bonuses.find(attack_bonus)+1 < attack_bonuses.size():
			out += SettingsGlobals.bb_line
	#print(out)
	#out.trim_suffix(SettingsGlobals.bb_line+'\n')
	
	return out
