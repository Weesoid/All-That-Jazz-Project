extends VBoxContainer
class_name CraftingMenu

@onready var crafting_slots_container = $Panel/MarginContainer/VBoxContainer/HBoxContainer
@onready var result_slot = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Result
@onready var result_slot_add = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Result/AddLabel
@onready var result_slot_count = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Result/CurrentCount
@onready var result_durability = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Result/Durability
@onready var recipe_menu: MiniRecipes = $MiniRecipes
var current_recipe = []
var craft_item: ResItem
var craft_count:int=-1
var crafting_slots
var repair_mode:bool=false
signal recipe_found(item)

func _ready():
	crafting_slots = crafting_slots_container.get_children().filter(func(control): return control is CraftingSlot)
	connectSlots()
	recipe_menu.showItems()
	await get_tree().process_frame
	
	for button in recipe_menu.item_button_map.values():
		button.craft_item.connect(autoCraft)
		InventoryGlobals.removed_item_from_inventory.connect(button.update.unbind(1))
		InventoryGlobals.added_item_to_inventory.connect(button.update.unbind(2))
		InventoryGlobals.stack_item_changed.connect(button.update.unbind(3))
		InventoryGlobals.item_repaired.connect(button.update.unbind(2).bind(craft_item))
	if InventoryGlobals.crafted_items.size() > 0:
		recipe_menu.show()

# CRAFT HANDLING
func connectSlots():
	for slot in crafting_slots:
		slot.current_recipe = current_recipe
		
		slot.item_received.connect(addMaterial.bind(slot))
		slot.item_dragged.connect(removeMaterial)
		slot.item_replaced.connect(removeMaterial)
		
		recipe_found.connect(slot.update_count)
		InventoryGlobals.removed_item_from_inventory.connect(slot.update_count.unbind(1).bind(craft_item))
		InventoryGlobals.added_item_to_inventory.connect(slot.update_count.unbind(2).bind(craft_item))
		InventoryGlobals.stack_item_changed.connect(slot.update_count.unbind(3).bind(craft_item))
		InventoryGlobals.item_repaired.connect(slot.update_count.unbind(2).bind(craft_item))

func addMaterial(item:ResItem, _last_item, slot:ItemSlot):
	current_recipe.append(item.getFilename())
	showResult()

func removeMaterial(item: ResItem):
	var item_filename = item.getFilename()
	if current_recipe.has(item_filename):
		current_recipe.erase(item_filename)
	showResult()

func showResult():
	var result = InventoryGlobals.getRecipeResult(current_recipe)
	repair_mode = result.has('is_repair_recipe')
	if result.is_empty():
		craft_item = null
		craft_count = -1
	else:
		craft_item = InventoryGlobals.loadItemResource(result[0])
		craft_count = result[1]
	
	if repair_mode:
		result_slot.disabled = !craft_item.canRepair(craft_count)
	else:
		result_slot.disabled = (craft_item == null or craft_count == -1) or !InventoryGlobals.canCraft(craft_item)
	#if repair_mode: print((craft_item == null or craft_count == -1), ' or ', !InventoryGlobals.canCraft(craft_item))
	recipe_found.emit(craft_item)
	if craft_item != null:
		highlightMissingItems(craft_item)
	else:
		resetSlotColors()
	updateResultSlot()

func _on_result_pressed():
	if craft_item == null or craft_count == -1:
		return
	
	if repair_mode:
		craft_item.repair(1)
	else:
		InventoryGlobals.craftItem(craft_item)
	
	highlightMissingItems(craft_item)
	updateResultSlot()
	if (!repair_mode and !InventoryGlobals.canCraft(craft_item)) or (repair_mode and !craft_item.canRepair(craft_count)):
		result_slot.disabled = true
		craft_item = null
		craft_count = -1
#	print('inputting: ', craft_item)
#	for slot in crafting_slots:
#		slot.update_count(craft_item)

func highlightMissingItems(item_to_craft:ResItem):
	await get_tree().process_frame
	var recipe = InventoryGlobals.getRecipe(item_to_craft)
	for slot in crafting_slots:
		if slot.item == null or !recipe.has(slot.item.getFilename()): continue
		if !InventoryGlobals.hasItem(slot.item, recipe[slot.item.getFilename()]):
			slot.modulate = Color.DARK_RED
		else:
			slot.modulate = Color.WHITE

func resetSlotColors():
	for slot in crafting_slots:
		if slot.item != null and !InventoryGlobals.hasItem(slot.item):
			slot.modulate = Color.DARK_RED
		else:
			slot.modulate = Color.WHITE

func updateResultSlot():
	if craft_item == null:
		result_slot.setItem(null)
	else:
		result_slot.setItem(craft_item)
	setResultLabels()

func setResultLabels():
	if craft_item == null:
		result_durability.hide()
		result_slot_add.hide()
		result_slot_count.hide()
	elif repair_mode:
		result_durability.setWeapon(craft_item)
		result_slot_add.text = "1"
		result_durability.show()
		result_slot_add.show()
		result_slot_count.hide()
	elif craft_item != null:
		var count_data = ItemComponentIcon.getCurrentCountString(craft_item)
		result_slot_count.text = count_data[0]
		result_slot_count.modulate = count_data[1]
		result_slot_add.text = '+'+str(InventoryGlobals.getCraftCount(craft_item.getFilename()))
		result_slot_add.show()
		result_slot_count.show() 
		result_durability.hide()
		if !InventoryGlobals.canCraft(craft_item):
			result_slot_add.hide()

func autoCraft(item:ResItem):
#	if !InventoryGlobals.canCraft(item):
#		return
	
	var recipe = InventoryGlobals.getRecipe(item)
	var recipe_items = recipe.keys()
	var recipe_index = 0
	
	current_recipe.sort()
	recipe_items.sort()
	
	if current_recipe != recipe_items:
		for slot in crafting_slots:
			slot.setItem(null)
		for slot in crafting_slots:
			if recipe_index != recipe_items.size():
				slot._drop_data(Vector2.ZERO, InventoryGlobals.loadItemResource(recipe_items[recipe_index]))
				recipe_index += 1
				await get_tree().create_timer(0.05).timeout
	
	await get_tree().process_frame
	result_slot.pressed.emit()

func resetCrafting():
	for slot in crafting_slots:
		slot.setItem(null)
