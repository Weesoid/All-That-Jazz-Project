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
@export var conditional_bonuses:Dictionary ={
	'damage':0,
	'duration':0
}
@export var bonus_condition: ResEffectCondition

## Returns [<effect>, <override_data>]
func getDotEffect(target:ResCombatant=null):
	var effect:String
	var temp = bonus_condition.isPassed(target)
	var conditions_passed = target != null and temp
	print('cond passed? ', target != null, ' and ', temp)
	var calculated_damage = damage if !conditions_passed else damage + conditional_bonuses['damage']
	var calculated_duration = duration if !conditions_passed else duration + conditional_bonuses['duration']
	
	var override_data = {'be_tickdmg':{'damage':calculated_damage}}
	if dot_effect == DotEffect.POISON:
		override_data['max_duration']= calculated_duration
	elif dot_effect == DotEffect.BLEED:
		override_data['extend_duration'] = calculated_duration
	
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

func getBonusConditionString()->String:
	if bonus_condition == null:
		return ''
	
	var msg_icon = getDotStatusEffect().getMessageIcon()
	var icon_color = getDotStatusEffect().getIconColor(true)
	var out = '\n[img] res://images/status_icons/small_buff.png[/img]'+icon_color
	if dot_effect == DotEffect.BLEED:
		out += '+'+str(conditional_bonuses['duration'])+msg_icon+'[/color] '
	else:
		out += '%s%s (%s turns) ' % [
		damage+conditional_bonuses['damage'], 
		msg_icon, 
		duration+conditional_bonuses['duration']
		] + '[/color]'
	
	out += ' '+str(bonus_condition).trim_prefix('\n')
	return out
