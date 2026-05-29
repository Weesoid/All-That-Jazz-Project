extends ResAbilityEffect
class_name ResAddTPEffect

@export var add_amount: int

func _to_string():
	return 'Add %s [img]res://images/user_interface/tp_particle.png[/img]' % add_amount # Probably continue this idk
