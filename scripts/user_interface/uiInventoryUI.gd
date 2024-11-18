# I DO NOT LIKE THIS, THIS IS A MESS!! But whatever.
# >:/
extends Control

@onready var inventory_grid = $PanelContainer2/MarginContainer/ScrollContainer/TabContainer
@onready var item_info_panel = $Infomration
@onready var item_info = $Infomration/ItemInfo/DescriptionLabel2
@onready var item_general_info = $Infomration/GeneralInfo
@onready var space_label = $Space

func _ready():
	InventoryGlobals.sortItems()
	updateInventory()
	resetDescription()
	if inventory_grid.get_child_count() > 0:
		inventory_grid.get_child(0).grab_focus()

#func _process(_delta):
#	space_label.text = '%s / %s' % [InventoryGlobals.INVENTORY.size(), InventoryGlobals.INVENTORY_SPACE]

func updateInventory():
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()
	
	for item in InventoryGlobals.INVENTORY:
		inventory_grid.add_child(createButton(item))
	
	OverworldGlobals.setMenuFocus(inventory_grid)

func createButton(item: ResItem):
	var button = OverworldGlobals.createItemButton(item)
	button.pressed.connect(func(): setButtonFunction(item))
	button.focus_entered.connect(func(): updateItemInfo(item))
	button.focus_exited.connect(func(): resetDescription())
	button.mouse_entered.connect(func(): updateItemInfo(item))
	button.mouse_exited.connect(func(): resetDescription())
	
	if item is ResStackItem:
		var label = Label.new()
		label.text = str(item.STACK)
		label.theme = preload("res://design/OutlinedLabel.tres")
		button.add_child(label)
	
	return button

func updateItemInfo(item):
	item_info.text = item.getInformation()
	item_general_info.text = item.getGeneralInfo()
	item_info_panel.show()

func setButtonFunction(item):
	item_info.text = '[center]'+ item.NAME.to_upper() + '[/center]\n'
	item_info.text += item.getInformation()
	item_general_info.text = item.getGeneralInfo()
	item_info_panel.show()
	
	if item is ResProjectileAmmo:
		item.equip()
	
	updateInventory()
	if InventoryGlobals.hasItem(item):
		focusItem(item)

func focusItem(item: ResItem):
	for button in inventory_grid.get_children():
		if button.tooltip_text == item.NAME:
			button.grab_focus()

func resetDescription():
	item_info.text = ''
	item_general_info.text = '[img]res://images/sprites/circle_filled.png[/img]%s' % PlayerGlobals.CURRENCY
