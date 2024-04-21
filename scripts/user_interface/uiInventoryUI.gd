# I DO NOT LIKE THIS, THIS IS A MESS!! But whatever.
# >:/
extends Control

@onready var inventory_grid = $PanelContainer2/MarginContainer/ScrollContainer/TabContainer
@onready var item_info_panel = $Infomration
@onready var item_info = $Infomration/ItemInfo/DescriptionLabel2
@onready var item_general_info = $Infomration/GeneralInfo

func _ready():
	updateInventory()

func updateInventory():
	for child in inventory_grid.get_children():
		child.queue_free()
	
	for item in InventoryGlobals.INVENTORY:
		inventory_grid.add_child(createButton(item))

func createButton(item: ResItem):
	var button = preload("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.theme = preload("res://design/ItemButtons.tres")
	button.icon = item.ICON
	button.tooltip_text = item.NAME
	button.gui_input.connect(func(input): setButtonFunction(input, item, button))
	
	if item is ResStackItem:
		var label = Label.new()
		label.text = str(item.STACK)
		label.theme = preload("res://design/OutlinedLabel.tres")
		button.add_child(label)
	
	return button

func setButtonFunction(event, item, button: Button):
	item_info.text = '[center]'+ item.NAME.to_upper() + '[/center]\n'
	item_info.text += item.getInformation()
	item_general_info.text = item.getGeneralInfo()
	item_info_panel.show()
	
	if Input.is_action_pressed("ui_alt_accept"):
		if item is ResProjectileAmmo:
			item.equip()
		elif item is ResConsumable:
			item.applyOverworldEffects()
		elif item is ResUtilityCharm:
			item.equip(PlayerGlobals.TEAM[0])
		
		updateInventory()
