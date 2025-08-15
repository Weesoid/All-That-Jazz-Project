extends Control
class_name InventoryUI

@onready var inventory_grid = $MarginContainer/ScrollContainer/TabContainer
@onready var space_label = $Space
var show_space:bool=false
func _ready():
	InventoryGlobals.sortItems()
	updateInventory()
	if inventory_grid.get_child_count() > 0:
		inventory_grid.get_child(0).grab_focus()
	show_space = float(InventoryGlobals.inventory.size()) / InventoryGlobals.max_inventory >= 0.75

func _process(_delta):
	if show_space:
		space_label.text = '%s / %s' % [InventoryGlobals.inventory.size(), InventoryGlobals.max_inventory]

func updateInventory():
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()
	
	for item in InventoryGlobals.inventory:
		inventory_grid.add_child(createButton(item))
	
	#OverworldGlobals.setMenuFocus(inventory_grid)

func createButton(item: ResItem):
	var button = OverworldGlobals.createItemButton(item)
	button.pressed.connect(func(): setButtonFunction(item))
	
	if item is ResStackItem:
		var label = Label.new()
		label.text = str(item.stack)
		label.theme = load("res://design/OutlinedLabel.tres")
		button.add_child(label)
	
	return button

func setButtonFunction(item):
	if item is ResProjectileAmmo:
		item.equip()
	
	updateInventory()
	if InventoryGlobals.hasItem(item):
		focusItem(item)

func focusItem(item: ResItem):
	for button in inventory_grid.get_children():
		if button.tooltip_text == item.name:
			button.grab_focus()
