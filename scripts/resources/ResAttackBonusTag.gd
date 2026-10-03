extends ResAttackBonus
class_name ResAttackBonusTag

@export var tag:String
@export_multiline var override_description:String = 'Hey wees u should really add this tags description to CombatExtras.STAT_DESCRIPTIONS'

func getAttackEffect(_target:ResCombatant=null):
	return {tag: true}

func _to_string():
	var base: String = CombatExtras.STAT_DESCRIPTIONS[tag] if CombatExtras.STAT_DESCRIPTIONS.has(tag) else override_description
	base += getStringCondition()
	return base
