extends ResAbilityEffect
class_name ResAddTPEffect

@export var add_amount: int

func _to_string():
	return 'Add %s TP' % add_amount # Probably continue this idk
