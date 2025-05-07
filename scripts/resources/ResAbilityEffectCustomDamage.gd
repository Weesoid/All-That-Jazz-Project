extends ResAbilityEffect
class_name ResCustomDamageEffect

@export var use_caster: bool
@export var damage: int
@export var crit_chance: float = -1.0
@export var variation: float = -1.0
@export var can_crit: bool = false
@export var can_miss: bool = false
@export var trigger_on_hits = false
@export var message: = ''
@export var apply_status: ResStatusEffect
@export var indicator_bb:  String = ''
