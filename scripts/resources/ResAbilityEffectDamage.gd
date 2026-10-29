## Basically the "Attack" action. Requires a caster to execute.
extends ResAbilityAction
class_name ResAttackAction

enum DamageType {
	MELEE,
	RANGED,
	RANGED_PIERCING,
	ADAPTIVE
}

@export var damage_type: DamageType
@export var damage_properties: Array[ResDamageProperty]
@export var damage_modifier: float = 1.0
@export var cast_animation: Dictionary= {'animation': '', 'go_to_target': false}
@export var can_crit: bool = true
@export var return_pos: bool = true
@export var indicator_bb:  String = ''
@export var projectile_texture: Texture

func getAttackBonuses(target:ResCombatant):
	return ResAttackAction.getPassedAttackBonuses(target, damage_properties) 

static func getPassedAttackBonuses(target:ResCombatant, p_damage_properties: Array):
	var out = {}
	
	for attack_bonus in p_damage_properties:
		if attack_bonus == null or !attack_bonus.conditionsPassed(target): continue
		out = CombatGlobals.combineDictionaries(out,attack_bonus.getAttackEffect(target))
	
	return out 

func _to_string():
	var out=''
	
	#out += stringifyCondition()
#	if is_combo_effect:
#		out += 'On [img]res://images/status_icons/icon_combo.png[/img]:\n'
	if damage_type == DamageType.MELEE or cast_animation['animation'].to_lower().contains('melee'):
		out += "[img]res://images/user_interface/icon_melee.png[/img] "
	elif (damage_type == DamageType.RANGED or damage_type == DamageType.RANGED_PIERCING) or cast_animation['animation'].to_lower().contains('ranged'):
		out += "[img]res://images/user_interface/icon_range.png[/img] "
	elif damage_type == DamageType.ADAPTIVE:
		out += "[img]res://images/user_interface/icon_melee.png[/img] "
		out += "[img]res://images/user_interface/icon_range.png[/img] "
	
	if damage_modifier > 1.0 or damage_modifier < 1.0:
		var op_sign
		if damage_modifier > 1.0:
			op_sign = SettingsGlobals.ui_colors['up-bb']+'+[/color]'
		elif damage_modifier < 1.0:
			op_sign = SettingsGlobals.ui_colors['down-bb']+'[/color]'
		out += op_sign+SettingsGlobals.colorValueBB((damage_modifier*100)-100,0.0)+'% DMG[/color]\n'
	else:
		out += '\n'
	
	for attack_bonus in damage_properties:
		if !attack_bonus.has_method('_to_string'): continue
		out += str(attack_bonus)
		if damage_properties.find(attack_bonus)+1 < damage_properties.size():
			out += SettingsGlobals.bb_line
	#print(out)
	#out.trim_suffix(SettingsGlobals.bb_line+'\n')
	
	return out
