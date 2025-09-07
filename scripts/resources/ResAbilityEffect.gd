extends Resource
class_name ResAbilityEffect

enum AnimateOn {
	TARGET,
	CASTER
}

## This effect will not execute unless the target has a combo token
@export var condition: String
@export var is_combo_effect: bool
@export var sound_effect: String = ''
@export var animation: PackedScene
@export var animation_time: float = 0.0
@export var animate_on: AnimateOn

func checkConditions(target: ResCombatant, caster: ResCombatant)-> bool:
	print(condition)
	if condition == '':
		return true
	
	var condition_data = condition.split('/')
	print('check1: ',condition_data)
	var combatant
	match condition_data[0]:
		't': combatant = target
		'c': combatant = caster
	condition_data.remove_at(0)
	print('check2: ',condition_data)
	for i in condition_data.size():
		if !CombatGlobals.checkConditions(condition_data[i].split('/'), combatant):
			return false
	
	return true

func stringifyConditionUnit()-> String:
	if condition.split('/')[0] == 't':
		return 'Target'
	elif condition.split('/')[0] == 'c':
		return 'Self'
	else:
		return ''

func stringifyCondition():
	if condition != '':
		return CombatGlobals.stringifyBonusStatConditions(condition.split('/'), stringifyConditionUnit())+' '
	else:
		return ''
