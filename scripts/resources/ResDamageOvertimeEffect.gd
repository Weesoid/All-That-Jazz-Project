extends Resource
class_name ResDamageOvertimeEffect

enum DotEffect {
	BURN,
	POISON,
	BLEED
}

@export var dot_effect: DotEffect
@export var damage: int
@export var duration: int

## Returns [<effect>, <override_data>]
func getDotEffect():
	var effect:String
	var override_data = {'be_tickdmg':{'damage':damage},'max_duration':duration}
	if dot_effect == DotEffect.BURN:
		effect = 'Burn'
	elif dot_effect == DotEffect.POISON:
		effect = 'Poison'
	elif dot_effect == DotEffect.BLEED:
		effect = 'Bleed'
	
	return [effect, override_data]

func getDotStatusEffect()-> ResStatusEffect:
	if dot_effect == DotEffect.BURN:
		return CombatGlobals.loadStatusEffect('Burn')
	elif dot_effect == DotEffect.POISON:
		return CombatGlobals.loadStatusEffect('Poison')
	elif dot_effect == DotEffect.BLEED:
		return CombatGlobals.loadStatusEffect('Bleed')
	
	return null
