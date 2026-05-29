extends Resource
class_name ResAttackBonus

var target_text:String = SettingsGlobals.ui_colors['down-bb']+'Target: [/color]'
var self_text:String = SettingsGlobals.ui_colors['up-bb']+'Self: [/color]'
@export var condition: ResEffectCondition #= preload()

func getAttackEffect():
	return {'attack_key':null}

func conditionsPassed(target:ResCombatant):
	return condition == null or condition.isPassed(target)

func getStringCondition():
	return str(condition) if condition != null else ''
