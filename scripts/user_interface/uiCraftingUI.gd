extends Control

@onready var component_core = $Craftables/CenterContainer/GridContainer/CoreComp
@onready var component_a = $Craftables/CenterContainer/GridContainer/CompA
@onready var component_b = $Craftables/CenterContainer/GridContainer/CompB
@onready var craft_button = $Craftables/CenterContainer/GridContainer/Craft
@onready var item_select = $ItemSelect
@onready var item_select_buttons = $ItemSelect/SelectCharms/VBoxContainer
@onready var item_select_info = $ItemSelect/Infomration
@onready var item_select_info_main = $ItemSelect/Infomration/ItemInfo/DescriptionLabel2
@onready var item_select_info_general = $ItemSelect/Infomration/GeneralInfo
var all_components: Array[ResItem] = [null, null, null]

var selected_recipe: ResRecipe

func _process(_delta):
	if InventoryGlobals.RECIPES.has(recipeToString()):
		craft_button.icon = InventoryGlobals.getRecipeResult(recipeToString()).ICON
		craft_button.text = 'Craft %s' % InventoryGlobals.getRecipeResult(recipeToString()).NAME	
		craft_button.show()
		craft_button.disabled = !canAddToInventory()
	else:
		craft_button.hide()

func _on_ready():
	component_core.pressed.connect(func(): showItems(component_core, 0))
	component_a.pressed.connect(func(): showItems(component_a, 1))
	component_b.pressed.connect(func(): showItems(component_b, 2))
	craft_button.connect('pressed', craft)

func _exit_tree():
	for item in all_components:
		if item != null:
			InventoryGlobals.addItemResource(item)

func canAddToInventory():
	var result_data = InventoryGlobals.getRecipeResult(recipeToString(), true)
	
	if result_data[1] != null:
		return InventoryGlobals.canAdd(result_data[0], result_data[1], false)
	else:
		return InventoryGlobals.canAdd(result_data[0], 1, false)

func recipeToString()-> Array:
	var out = [null, null, null]
	for i in range(3):
		if all_components[i] != null:
			out[i] = all_components[i].NAME
	
	return out

func craft():
	var craft_result = InventoryGlobals.getRecipeResult(recipeToString())
	
	InventoryGlobals.craftItem(all_components)
	for i in range(all_components.size()):
		if all_components[i] == null: continue
		InventoryGlobals.removeItemResource(all_components[i], 1, false)
		updateComponentSlot(i)

func updateComponentSlot(slot: int):
	var item = all_components[slot]
	if !InventoryGlobals.hasItem(item):
		removeItemFromSlot(slot)
	elif item is ResStackItem:
		match slot:
			0: 
				component_core.text = '%s x%s' % [item.NAME, item.STACK]
			1:
				component_a.text = '%s x%s' % [item.NAME, item.STACK]
			2:
				component_b.text = '%s x%s' % [item.NAME, item.STACK]

func showItems(slot_button: Button, slot: int):
	for child in item_select_buttons.get_children():
		child.free()
	
	item_select.show()
	var cancel_button = OverworldGlobals.createCustomButton()
	cancel_button.theme = preload("res://design/ItemButtons.tres")
	cancel_button.icon = preload('res://images/sprites/icon_cross.png')
	cancel_button.pressed.connect(
		func():
			if all_components[slot] != null:
				removeItemFromSlot(slot)
			item_select.hide()
	)
	item_select_buttons.add_child(cancel_button)
	
	for item in InventoryGlobals.INVENTORY:
		if all_components.has(item): continue
		var button = OverworldGlobals.createItemButton(item)
		button.pressed.connect(
			func():
				addItemToSlot(item, slot, slot_button)
		)
		button.mouse_entered.connect(func(): updateItemDescription(item))
		item_select_buttons.add_child(button)

func addItemToSlot(item: ResItem, slot:int, slot_button: Button):
	if item.MANDATORY:
		InventoryGlobals.removeItemResource(item) # This will show 'Cannot remove item'
	else:
		slot_button.icon = item.ICON
		if item is ResStackItem:
			slot_button.text = '%s x%s' % [item.NAME, item.STACK]
		else:
			slot_button.text = item.NAME
		
		all_components[slot] = item
		item_select.hide()

func removeItemFromSlot(slot: int):
	match slot:
		0:
			component_core.text = 'CORE COMPONENT'
			component_core.icon = preload("res://images/sprites/icon_plus.png")
		1:
			component_a.text = 'COMPONENT A'
			component_a.icon = preload("res://images/sprites/icon_plus.png")
		2:
			component_b.text = 'COMPONENT B'
			component_b.icon = preload("res://images/sprites/icon_plus.png")
	all_components[slot] = null

func updateItemDescription(item: ResItem):
	if item == null:
		return
	
	item_select_info.show()
	item_select_info_general.text = item.getGeneralInfo()
	item_select_info_main.text = item.getInformation()

func _on_repair_pressed():
	InventoryGlobals.repairAllItems()
