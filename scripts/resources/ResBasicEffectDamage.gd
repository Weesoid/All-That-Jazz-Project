extends ResBasicEffect
class_name ResStatusDamageEffect

@export var damage: int
@export var rank_scaling:bool = false
@export var attack_bonuses: Array[ResAttackBonus] = []
@export var crit_chance: float = -1.0
@export var variation: float = -1.0
@export var trigger_on_hits:bool = false
@export var sound_path:String = ''
@export var indicator_bb:  String = ''

func _to_string():
	return str(damage)

func getAttackBonuses(target:ResCombatant):
	var out = ResAttackEffect.getPassedAttackBonuses(target, attack_bonuses)
	out['is_dot'] = true
	return out 
