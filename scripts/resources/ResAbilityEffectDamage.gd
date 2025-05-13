extends ResAbilityEffect
class_name ResDamageEffect

enum DamageType {
	MELEE,
	RANGED,
	RANGED_PIERCING,
	CUSTOM
}

## Animation the caster will do.
@export var damage_type: DamageType
## Only applicable if damage type is "Custom". What animation the caster will do.
@export var cast_animation: Dictionary= {'animation': '', 'go_to_target': false} 
@export var damage := 0
@export var can_miss: bool = true
@export var can_crit: bool = true
@export var bonus_stats: Dictionary
@export var apply_status: ResStatusEffect
@export var move: int = 0
@export var move_count: int = 1
@export var return_pos: bool = true
@export var indicator_bb:  String = ''
## Unlike "is_combo_effect" this effect will execute even without the target having a combo token. Token is consumed once the effect is done.
@export var has_combo_effects: bool 
## Which variables will be applied if the target has a combo token.
@export var combo_properties: Dictionary = {
	'do_not_return_pos': false,
	'move': false,
	'status_effect': false,
	'bonus_stats': false
}
var do_not_return_pos: bool=false

func canCombo(target: ResCombatant, check_property:String='')-> bool:
	return has_combo_effects and target.hasStatusEffect('Combo') and (check_property == '' or combo_properties[check_property])
