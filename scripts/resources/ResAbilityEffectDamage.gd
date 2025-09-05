## Basically the "Attack" action. Requires a caster to execute.
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
@export var damage_modifier: float = 1.0
@export var can_miss: bool = true
@export var can_crit: bool = true
## Additional stats to be applied on usage.
## Conditions:
## 		hp = Health threshold ex. crit/hp:>:0.5 or crit/hp:<:0.75
## 		s = Status effect ex. crit/s:bleed
##		combo =  Only execute if target has combo token. Combo token is consumed. ex. crit/combo:0.75
##			combo! = The same as combo but it will not consume the combo token. ex. crit/combo!:0.75
## 	Special stats:
## 		execute = Execute combatant on a certain health threshold ex. "execute": 0.5 (executes at 50% health)
##		status_effect = Apply status effect ex. "status_effect": "Poison" (Must use file sys name) ("Poison,Riposte" will add an array of status effects)
##		move = Move the target combatant. e.g. "move": "f,1" (Means forward one space) (b,2 would mean backward 2 spaces)
@export var bonus_stats: Dictionary
@export var return_pos: bool = true
@export var indicator_bb:  String = ''
@export var plant_self_on_combo: bool
var do_not_return_pos: bool=false

func _to_string():
	return str(damage_modifier)
