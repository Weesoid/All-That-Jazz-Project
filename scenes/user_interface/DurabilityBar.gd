extends Control
class_name DurabilityBar

@onready var bar = $ProgressBar
var weapon: ResWeapon

func setWeapon(p_weapon):
	weapon = p_weapon
	bar.value = weapon.durability
	bar.max_value = weapon.max_durability

func _ready():
	if weapon != null:
		setWeapon(weapon)
		InventoryGlobals.item_repaired.connect(update_values.unbind(2))

func update_values():
	bar.value = weapon.durability
