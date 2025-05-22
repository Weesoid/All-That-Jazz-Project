extends ResAbilityEffect
class_name ResCustomDamageEffect

@export var use_caster: bool
@export var cast_animation: String
@export var damage: int
@export var use_damage_formula: bool
@export var crit_chance: float = 0.0
@export var variation: float = -1.0
@export var can_crit: bool = false
@export var bonus_stats: Dictionary
@export var can_miss: bool = false
@export var trigger_on_hits = false
@export var message: = ''
@export var apply_status: ResStatusEffect
@export var indicator_bb:  String = ''
@export var has_combo_effects: bool 
@export var combo_properties: Dictionary = {
	'status_effect': false,
	'bonus_stats': false
}
@export var effect_only_combo_targets: bool

func canCombo(target: ResCombatant, check_property:String='')-> bool:
	return has_combo_effects and target.hasStatusEffect('Combo') and (check_property == '' or combo_properties[check_property])
