extends ResAbilityEffect
class_name ResDamageEffect

enum DamageType {
	MELEE,
	RANGED,
	RANGED_PIERCING
}

@export var damage_type: DamageType
@export var damage := 0
@export var can_miss: bool = true
@export var can_crit: bool = true
@export var apply_status: ResStatusEffect
@export var move: int = 0
@export var move_count: int = 1
@export var return_pos: bool = true
