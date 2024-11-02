extends ResAbilityEffect
class_name ResOnslaughtEffect

enum Target {
	SINGLE,
	MULTI
}

@export var animation_name: String = 'Onslaught'
@export var damage: int
@export var target: Target
@export var projectile_frame: float
