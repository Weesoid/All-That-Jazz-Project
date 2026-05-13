extends Control
class_name InventoryUI

@onready var item_container = $MarginContainer/ScrollContainer/HFlowContainer/Items/Items
@onready var ammo_container = $MarginContainer/ScrollContainer/HFlowContainer/Ammo/Items
@onready var camp_container = $MarginContainer/ScrollContainer/HFlowContainer/CampItems/Items
@onready var combat_container = $MarginContainer/ScrollContainer/HFlowContainer/CombatItems/Items
@onready var charm_container = $MarginContainer/ScrollContainer/HFlowContainer/Charms/Items
@onready var space_label = $Space

var show_space:bool=false
var item_button_map = {}

func _ready():
	InventoryGlobals.sortItems()
	updateInventory()
	InventoryGlobals.added_item_to_inventory.connect(addButton.unbind(1))
	InventoryGlobals.removed_item_from_inventory.connect(removeButton)
	#InventoryGlobals.item_equipped.connect(removeButton.unbind(1))
	#show_space = float(InventoryGlobals.inventory.size()) / InventoryGlobals.max_inventory >= 0.75
#func _process(_delta):
#	if show_space:
#		space_label.text = '%s / %s' % [InventoryGlobals.inventory.size(), InventoryGlobals.max_inventory]

func updateInventory():
	for item in InventoryGlobals.inventory:
		addButton(item)
	updateCategories()


func removeButton(item):
	if !item_button_map.has(item): return
	
	item_button_map[item].queue_free()
	item_button_map.erase(item)
	updateCategories()

func addButton(item):
	#if item_button_map.has(item): return
	
	var button = OverworldGlobals.createItemButton(item)
	if item is ResCharm:
		charm_container.add_child(button)
	elif item is ResProjectileAmmo:
		ammo_container.add_child(button)
	elif item is ResCampItem:
		camp_container.add_child(button)
	elif item is ResEquippable:
		combat_container.add_child(button)
	else:
		item_container.add_child(button)
	
	item_button_map[item] = button
	updateCategories()

func updateCategories():
	await get_tree().process_frame
	item_container.get_parent().visible = item_container.get_child_count() > 0
	ammo_container.get_parent().visible = ammo_container.get_child_count() > 0
	camp_container.get_parent().visible = camp_container.get_child_count() > 0
	combat_container.get_parent().visible = combat_container.get_child_count() > 0
	charm_container.get_parent().visible = charm_container.get_child_count() > 0

#	for child in inventory_grid.get_children():
#		inventory_grid.remove_child(child)
#		child.queue_free()
#
#	for item in InventoryGlobals.inventory:
#		inventory_grid.add_child(createButton(item))
	
	#OverworldGlobals.setMenuFocus(inventory_grid)

#func createButton(item: ResItem):
#	var button = OverworldGlobals.createItemButton(item)
#	button.pressed.connect(func(): setButtonFunction(item))
#
#	if item is ResStackItem:
#		var label = Label.new()
#		label.text = str(item.stack)
#		label.theme = load("res://design/OutlinedLabel.tres")
#		button.add_child(label)
#
#	return button

func setButtonFunction(item):
	if item is ResProjectileAmmo:
		item.equip()
	
	updateInventory()
	if InventoryGlobals.hasItem(item):
		focusItem(item)

func focusItem(item: ResItem):
	pass
#	for button in inventory_grid.get_children():
#		if button.tooltip_text == item.name:
#			button.grab_focus()
