extends Control
class_name DurabilityBar

@onready var bar = $ProgressBar
var weapon: ResWeapon

#func _init(p_weapon):
#	weapon = p_weapon

	#InventoryGlobals.stack_item_changed.connect(updateCount)

func _ready():
	print(weapon)
	bar.value = weapon.durability
	bar.max_value = weapon.max_durability

