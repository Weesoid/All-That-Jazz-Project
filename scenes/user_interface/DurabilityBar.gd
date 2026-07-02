extends Control
class_name DurabilityBar

@onready var bar = $ProgressBar
var item: ResItem

func setItem(p_item):
	item = p_item
	bar.value = item.durability
	bar.max_value = item.max_durability
	if !InventoryGlobals.item_repaired.is_connected(update_values):
		InventoryGlobals.item_repaired.connect(update_values.unbind(2))
	if !InventoryGlobals.item_used.is_connected(update_values):
		InventoryGlobals.item_used.connect(update_values.unbind(1))
	update_values()

func _ready():
	if item != null:
		setItem(item)
		if !InventoryGlobals.item_repaired.is_connected(update_values):
			InventoryGlobals.item_repaired.connect(update_values.unbind(2))
		if !InventoryGlobals.item_used.is_connected(update_values):
			InventoryGlobals.item_used.connect(update_values.unbind(1))

func update_values():
	bar.value = item.durability
	bar.max_value = item.max_durability
