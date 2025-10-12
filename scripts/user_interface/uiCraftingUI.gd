extends Control

const MINI_INVENTORY = preload("res://scenes/user_interface/MiniInventory.tscn")
const MINI_INV_RECIPES = preload("res://scenes/user_interface/MiniRecipes.tscn")
const MINI_INV_REPAIRS = preload("res://scenes/user_interface/MiniRepair.tscn")
const PLUS_ICON = preload("res://images/sprites/icon_plus.png")
const CRAFT_ICON = preload("res://images/sprites/icon_resources.png")

@onready var base = $Craftables/VBoxContainer/CenterContainer/GridContainer
@onready var recipes_button = $Craftables/VBoxContainer/OtherActions/Recipes
@onready var repair_button = $Craftables/VBoxContainer/OtherActions/Repair
@onready var component_a = $Craftables/VBoxContainer/CenterContainer/GridContainer/CompA
@onready var component_b = $Craftables/VBoxContainer/CenterContainer/GridContainer/CompB
@onready var component_c = $Craftables/VBoxContainer/CenterContainer/GridContainer/CompC
@onready var craft_button = $Craftables/VBoxContainer/CenterContainer/GridContainer/Craft
var all_components: Array[String] = ['', '', '']
var is_crafting:bool=false
signal update_inventory

func _on_ready():
	component_a.pressed.connect(func(): showItems(component_a, 0))
	component_b.pressed.connect(func(): showItems(component_b, 1))
	component_c.pressed.connect(func(): showItems(component_c, 2))
	craft_button.connect('pressed', craft)
	OverworldGlobals.setMenuFocus(base)

func canRepair(min_scrap: int):
	return !InventoryGlobals.hasItem('ScrapSalvage') or InventoryGlobals.getItem('Scrap Salvage').stack < min_scrap

func canAddToInventory():
	var result = InventoryGlobals.getRecipeResult(all_components)
	return InventoryGlobals.canAdd(result[0], int(result[1]), false) and InventoryGlobals.canCraft(result[0].getFilename())

func craft(grab_focus:bool=true):
	InventoryGlobals.craftItem(all_components)
	
	for i in range(3):
		updateComponentSlot(i)
	
	craft_button.disabled = !canAddToInventory()
	checkRecipeResult()
	if grab_focus and !InventoryGlobals.recipes.has(all_components):
		component_c.grab_focus()
	OverworldGlobals.playSound("res://audio/sounds/580812__silverillusionist__craft-item-2.ogg")
	showPopTween(craft_button)


func updateComponentSlot(slot: int):
	if all_components[slot] == '':
		return
	
	var item = load("res://resources/items/%s.tres"%all_components[slot])
	var button = base.get_child(slot)
	button.icon = item.icon
	
	if item is ResStackItem:
		button.self_modulate = Color.WHITE
		button.get_node('Label').modulate = Color.WHITE
		button.get_node('Label').text = str(item.stack)
		button.get_node('Label').show()
		if item.stack <= 0:
			button.self_modulate = Color.RED
	elif item is ResCharm:
		button.self_modulate = Color.WHITE
		button.get_node('Label').modulate = Color.WHITE
		button.get_node('Label').text = str(InventoryGlobals.getCharms(item).size())
		button.get_node('Label').show()
		if InventoryGlobals.getCharms(item).size() <= 0:
			button.self_modulate = Color.RED
	else:
		button.get_node('Label').text = ''
		button.get_node('Label').hide()

func showItems(slot_button: Button, slot: int):
	var mini_inv = MINI_INVENTORY.instantiate()
	slot_button.add_child(mini_inv)
	mini_inv.showItems(func(item): return !all_components.has(item.getFilename()))
	mini_inv.exit_button.pressed.connect(
		func(): 
			removeItemFromSlot(slot)
			OverworldGlobals.setMenuFocus(base)
			)
	for item in mini_inv.item_button_map.keys():
		mini_inv.item_button_map[item].pressed.connect(
			func(): 
				addItemToSlot(item, slot, slot_button)
				)

func addItemToSlot(item: ResItem, slot:int, slot_button: Button,grab_focus:bool=true):
	slot_button.modulate = Color.WHITE
	if item.mandatory:
		return
	
	all_components[slot] = item.getFilename()
	updateComponentSlot(slot)
	updateAccesibleButtons()
	OverworldGlobals.setMenuFocusMode(base, true)
	OverworldGlobals.setMenuFocusMode(repair_button, true)
	showPopTween(slot_button)
	if grab_focus:
		slot_button.grab_focus()
	checkRecipeResult()

func showPopTween(button:Button):
	button.scale = Vector2(1.25,1.25)
	button.set_anchors_preset(Control.PRESET_CENTER)
	create_tween().tween_property(button,'scale',Vector2(1,1),0.25)

func checkRecipeResult():
	var result = InventoryGlobals.getRecipeResult(all_components)
	
	if result == null:
		craft_button.icon = CRAFT_ICON
		craft_button.get_node('RequiredLabel').hide()
		craft_button.get_node('Label').hide()
		craft_button.get_node('Label').modulate = Color.WHITE
		craft_button.disabled = true
		hideRequiredAmounts()
	else:
		craft_button.icon = result[0].icon
		if result[0] is ResStackItem and InventoryGlobals.hasItem(result[0]):
			var stack_item = InventoryGlobals.getItem(result[0])
			craft_button.get_node('Label').text = str(stack_item.stack)
			craft_button.get_node('Label').show()
			if stack_item.stack >= stack_item.max_stack:
				craft_button.get_node('Label').modulate = Color.YELLOW
			else:
				craft_button.get_node('Label').modulate = Color.WHITE
		else:
			craft_button.get_node('Label').hide()
		craft_button.get_node('RequiredLabel').text = 'x'+str(result[1])
		craft_button.get_node('RequiredLabel').show()
		craft_button.disabled = !canAddToInventory()
		showRequiredAmounts(InventoryGlobals.getItemRecipe(result[0].getFilename()))

func showRequiredAmounts(recipe):
	var i = 0
	for component in recipe.keys():
		var button = base.get_child(i)
		var item = load("res://resources/items/%s.tres" % component)
		if InventoryGlobals.hasItem(item,recipe[component]):
			button.get_node('Label').modulate = Color.WHITE
		else:
			button.get_node('Label').modulate = Color.RED
		
		button.get_node('RequiredLabel').text = 'x'+str(recipe[component])
		button.get_node('RequiredLabel').show()
		i += 1
	
	
func hideRequiredAmounts():
	for i in range(3):
		base.get_child(i).get_node('RequiredLabel').hide()

func removeItemFromSlot(slot: int):
	#base.get_child(slot).scale = Vector2(1.25,1.25)
	#create_tween().tween_property(base.get_child(slot),'scale',Vector2(1,1),0.25)
	all_components[slot] = ''
	updateDisabledButtons()
	checkRecipeResult()

func updateAccesibleButtons():
	for i in range(all_components.size()):
		if all_components[i] != '' and i+1 != all_components.size() and base.get_children()[i+1].disabled:
			base.get_children()[i+1].disabled=false
			break

func updateDisabledButtons():
	var disable_button=false
	for i in range(all_components.size()):
		if all_components[i] == '':
			disable_button = true
			resetButton(base.get_children()[i])
			if i != 0:
				base.get_children()[i].disabled=true
			continue
		
		if disable_button:
			resetButton(base.get_children()[i])
			base.get_children()[i].disabled=true
			all_components[i] = ''
	updateAccesibleButtons()

func resetButton(button):
	button.icon = PLUS_ICON
	button.get_node('Label').modulate = Color.WHITE
	button.self_modulate = Color.WHITE
	button.get_node('Label').hide()
	button.get_node('RequiredLabel').hide()

func useRecipe(item_filename: String):
	if is_crafting:
		return
	
	is_crafting = true
	for i in range(3):
		removeItemFromSlot(i)
	var recipe = InventoryGlobals.getItemRecipe(item_filename)
	var i = 0
	OverworldGlobals.playSound("res://audio/sounds/421461__jaszunio15__click_46.ogg")
	for component_filename in recipe.keys():
		var item = load("res://resources/items/%s.tres" % component_filename)
		addItemToSlot(item,i,base.get_child(i),false)
		i += 1
	
	craft(false)
	OverworldGlobals.update_inventory.emit()
	
	is_crafting = false

func repairWeapon(weapon:ResWeapon, repair_count:int):
	if weapon.canRepair(repair_count):
		weapon.repair(repair_count)
		OverworldGlobals.update_inventory.emit()
		OverworldGlobals.playSound("res://audio/sounds/580813__silverillusionist__craft-item-3.ogg")

func _on_repair_pressed():
	OverworldGlobals.showMiniMenu(
		MINI_INV_REPAIRS, 
		repair_button, 
		1,
		func(item): 
			repairWeapon(item,item.max_durability-item.durability)
			OverworldGlobals.playSound("res://audio/sounds/580812__silverillusionist__craft-item-2.ogg")
			,
		func(item): return OverworldGlobals.getCombatantSquad('Player').has(item),
		func(item): repairWeapon(item,1)
		)

func _on_recipes_pressed():
	OverworldGlobals.showMiniMenu(
		MINI_INV_RECIPES, 
		recipes_button, 
		1,
		func(item): useRecipe(item.getFilename()))

func _on_repair_all_pressed():
	InventoryGlobals.repairAllItems()

func _on_repair_equipped_pressed():
	InventoryGlobals.repairAllItems(true)

func _on_component_pressed():
	pass # Replace with function body.
