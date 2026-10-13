extends ResAbilityAction
class_name ResHealResolveAction

@export var amount:int

func _to_string():
	return '[color=GREEN]Heal %s Resolve[/color]' % amount
