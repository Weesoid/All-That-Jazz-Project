extends Resource
class_name ResDamageProperty

var target_text:String = 'Target: '#SettingsGlobals.ui_colors['down-bb']+'Target: [/color]'
var self_text:String = 'Self: '#SettingsGlobals.ui_colors['up-bb']+'Self: [/color]'
@export var condition: ResEffectCondition #= preload()

func getAttackEffect(_target:ResCombatant=null):
	return {'attack_key':null}

func conditionsPassed(target:ResCombatant):
	return condition == null or condition.isPassed(target)

func getStringCondition():
	return str(condition) if condition != null else ''
