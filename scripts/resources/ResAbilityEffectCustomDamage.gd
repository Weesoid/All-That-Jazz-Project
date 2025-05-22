# A more general Damage effect. Does not need a caster. Best for independent damage or AoE attacks.
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
@export var message: String = ''
@export var indicator_bb:  String = ''
