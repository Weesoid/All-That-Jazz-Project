extends Control

@onready var base = $Craftables/CenterContainer/GridContainer
@onready var repair_button = $Repair
@onready var recipe_button = $Recipes
@onready var component_core = $Craftables/CenterContainer/GridContainer/CoreComp
@onready var component_a = $Craftables/CenterContainer/GridContainer/CompA
@onready var component_b = $Craftables/CenterContainer/GridContainer/CompB
@onready var craft_button = $Craftables/CenterContainer/GridContainer/Craft
@onready var item_select = $ItemSelect
@onready var item_select_buttons = $ItemSelect/MarginContainer/SelectCharms/VBoxContainer
var all_components: Array[ResItem] = [null, null, null]

func _process(_delta):
	if InventoryGlobals.RECIPES.has(recipeToString()) and InventoryGlobals.getRecipeResult(recipeToString()) != null:
		craft_button.icon = InventoryGlobals.getRecipeResult(recipeToString()).ICON
		craft_button.text = 'Craft %s' % InventoryGlobals.getRecipeResult(recipeToString()).NAME	
		craft_button.show()
		craft_button.disabled = canAddToInventory()
	elif InventoryGlobals.RECIPES.has(recipeToString()) and InventoryGlobals.getRecipeResult(recipeToString()) == null:
		craft_button.text = 'UH OH! PLEASE SHOW WEES THIS INVALID RECIPE!!!'
		craft_button.show()
		craft_button.disabled = true
	else:
		craft_button.hide()

func _on_ready():
	component_core.pressed.connect(func(): showItems(component_core, 0))
	component_a.pressed.connect(func(): showItems(component_a, 1))
	component_b.pressed.connect(func(): showItems(component_b, 2))
	craft_button.connect('pressed', craft)
	OverworldGlobals.setMenuFocus(base)
	if InventoryGlobals.CRAFTED.is_empty():
		recipe_button.hide()

func canAddToInventory():
	var result_data = InventoryGlobals.getRecipeResult(recipeToString(), true)
	if result_data[1] != null and result_data[0] is ResStackItem:
		return !InventoryGlobals.canAdd(result_data[0], int(result_data[1]), false)
	else:
		return !InventoryGlobals.canAdd(result_data[0], 1, false)


func recipeToString()-> Array:
	var out = [null, null, null]
	for i in range(3):
		if all_components[i] != null:
			out[i] = all_components[i].NAME
	
	return out

func craft():
	InventoryGlobals.craftItem(all_components)
	for i in range(all_components.size()):
		if all_components[i] == null: continue
		InventoryGlobals.removeItemResource(all_components[i], 1, false)
		updateComponentSlot(i)
	
	if !InventoryGlobals.RECIPES.has(recipeToString()):
		component_core.grab_focus()

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
		item_select_buttons.remove_child(child)
		child.queue_free()
	
	item_select.show()
	var cancel_button = OverworldGlobals.createCustomButton()
	cancel_button.theme = preload("res://design/ItemButtons.tres")
	cancel_button.icon = preload('res://images/sprites/icon_cross.png')
	cancel_button.focused_entered_sound = preload("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	cancel_button.click_sound = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")
	cancel_button.pressed.connect(
		func():
			if all_components[slot] != null:
				removeItemFromSlot(slot)
			item_select.hide()
			OverworldGlobals.setMenuFocusMode(base, true)
			OverworldGlobals.setMenuFocusMode(repair_button, true)
			slot_button.grab_focus()
	)
	item_select_buttons.add_child(cancel_button)
	cancel_button.grab_focus()
	OverworldGlobals.setMenuFocusMode(base, false)
	OverworldGlobals.setMenuFocusMode(repair_button, false)
	for item in InventoryGlobals.INVENTORY:
		if all_components.has(item): continue
		var button = OverworldGlobals.createItemButton(item)
		button.pressed.connect(func(): addItemToSlot(item, slot, slot_button))
		if item.MANDATORY: button.disabled = true
		item_select_buttons.add_child(button)

func showRecipes():
	for child in item_select_buttons.get_children():
		item_select_buttons.remove_child(child)
		child.queue_free()
	
	item_select.show()
	var cancel_button = OverworldGlobals.createCustomButton()
	cancel_button.theme = preload("res://design/ItemButtons.tres")
	cancel_button.icon = preload('res://images/sprites/icon_cross.png')
	cancel_button.focused_entered_sound = preload("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	cancel_button.click_sound = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")
	cancel_button.pressed.connect(
		func():
			item_select.hide()
			OverworldGlobals.setMenuFocusMode(base, true)
			OverworldGlobals.setMenuFocusMode(repair_button, true)
	)
	item_select_buttons.add_child(cancel_button)
	cancel_button.grab_focus()
	InventoryGlobals.CRAFTED.sort()
	for recipe in InventoryGlobals.CRAFTED:
		var button = preload("res://scenes/user_interface/CustomButton.tscn").instantiate()
		button.custom_minimum_size = Vector2(32, 32)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon = load("res://resources/items/%s.tres" % recipe).ICON
		button.theme = load("res://design/ItemButtons.tres")
		button.pressed.connect(func(): useRecipe(recipe))
		button.mouse_entered.connect(func(): showRecipeDescription(recipe))
		button.focus_entered.connect(func(): showRecipeDescription(recipe))
		item_select_buttons.add_child(button)

func addItemToSlot(item: ResItem, slot:int, slot_button: Button):
	slot_button.modulate = Color.WHITE
	if item.MANDATORY:
		return
	else:
		slot_button.icon = item.ICON
		if item is ResStackItem:
			slot_button.text = '%s x%s' % [item.NAME, item.STACK]
		else:
			slot_button.text = item.NAME
		
		all_components[slot] = item
		item_select.hide()
	
	OverworldGlobals.setMenuFocusMode(base, true)
	OverworldGlobals.setMenuFocusMode(repair_button, true)
	slot_button.grab_focus()

func removeItemFromSlot(slot: int):
	match slot:
		0:
			component_core.text = 'CORE COMPONENT'
			component_core.icon = preload("res://images/sprites/icon_plus.png")
			component_core.modulate = Color.WHITE
		1:
			component_a.text = 'COMPONENT A'
			component_a.icon = preload("res://images/sprites/icon_plus.png")
			component_a.modulate = Color.WHITE
		2:
			component_b.text = 'COMPONENT B'
			component_b.icon = preload("res://images/sprites/icon_plus.png")
			component_b.modulate = Color.WHITE
	
	all_components[slot] = null

func useRecipe(item: String):
	for i in range(3):
		removeItemFromSlot(i)
	
#	if item.split('.').size() > 1:
#		item = item.split('.')[0]
	for result in InventoryGlobals.RECIPES.keys():
		if InventoryGlobals.RECIPES[result].split('.')[0] == item:
			var i = 0
			for component in result:
				if InventoryGlobals.hasItem(component, 0, false):
					addItemToSlot(InventoryGlobals.getItem(component), i, base.get_child(i))
				elif component != null:
					base.get_child(i).text = '%s' % component
					base.get_child(i).icon = preload("res://images/sprites/cross.png")
					base.get_child(i).modulate = Color.DARK_GRAY
				i += 1

func showRecipeDescription(item_name: String):
	var out = ''
	for recipe in InventoryGlobals.RECIPES.keys():
		if InventoryGlobals.RECIPES[recipe].split('.')[0] == item_name:
			out += load("res://resources/items/%s.tres" % item_name).getInformation()+'\n\nRecipe: '
			var i = 1
			for component in recipe:
				if component != null:
					if InventoryGlobals.hasItem(component, 0, false):
						out += component
					else:
						out += '[color=red]'+component+'[/color]'
					if i != recipe.filter(func(a): return a != null).size():
						out += ', '
					i += 1
	
	#item_select_info_general.text = out

func _on_repair_pressed():
	InventoryGlobals.repairAllItems()

func _on_recipes_pressed():
	
	showRecipes()
