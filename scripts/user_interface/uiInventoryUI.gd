# I DO NOT LIKE THIS, THIS IS A MESS!! But whatever.
# >:/
extends Control

@onready var inventory_grid = $PanelContainer2/MarginContainer/ScrollContainer/TabContainer
@onready var item_info_panel = $Infomration
@onready var item_info = $Infomration/ItemInfo/DescriptionLabel2
@onready var item_general_info = $Infomration/GeneralInfo

func _ready():
	updateInventory()
	resetDescription()

func updateInventory():
	for child in inventory_grid.get_children():
		child.queue_free()
	
	for item in InventoryGlobals.INVENTORY:
		inventory_grid.add_child(createButton(item))

func createButton(item: ResItem):
	var button = OverworldGlobals.createItemButton(item)
	button.gui_input.connect(func(input): setButtonFunction(input, item, button))
	button.mouse_entered.connect(func(): updateItemInfo(item))
	button.mouse_exited.connect(func(): resetDescription())
	
	if item is ResStackItem:
		var label = Label.new()
		label.text = str(item.STACK)
		label.theme = preload("res://design/OutlinedLabel.tres")
		button.add_child(label)
	
	return button

func updateItemInfo(item):
	item_info.text = '[center]'+ item.NAME.to_upper() + '[/center]\n'
	item_info.text += item.getInformation()
	item_general_info.text = item.getGeneralInfo()
	item_info_panel.show()

func setButtonFunction(event, item, button: Button):
	item_info.text = '[center]'+ item.NAME.to_upper() + '[/center]\n'
	item_info.text += item.getInformation()
	item_general_info.text = item.getGeneralInfo()
	item_info_panel.show()
	
	if Input.is_action_just_pressed("ui_alt_accept"):
		if item is ResProjectileAmmo:
			item.equip()
		elif item is ResConsumable:
			item.applyOverworldEffects()
		elif item is ResUtilityCharm:
			if PlayerGlobals.EQUIPPED_CHARM == item:
				PlayerGlobals.EQUIPPED_CHARM.unequip()
			else:
				item.equip(PlayerGlobals.TEAM[0])
		
		updateInventory()

func resetDescription():
	if PlayerGlobals.hasUtilityCharm():
		item_info.text = '[img]%s[/img]	%s' % [PlayerGlobals.EQUIPPED_CHARM.ICON.resource_path, PlayerGlobals.EQUIPPED_CHARM.NAME]
	else:
		item_info.text = ''
	
	item_general_info.text = '[img]res://images/sprites/circle_filled.png[/img]%s' % PlayerGlobals.CURRENCY
