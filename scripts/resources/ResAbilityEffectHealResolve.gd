extends ResAbilityEffect
class_name ResHealResolveEffect

@export var amount:int

func _to_string():
	return '[color=GREEN]Heal %s Resolve[/color]' % amount
