extends Node

var INVENTORY: Array[ResItem] = []
var KNOWN_RECIPES: Array[ResRecipe] = []
var KNOWN_POWERS: Array[ResPower] = []
signal added_item_to_inventory

func _ready():
	KNOWN_RECIPES.append(load("res://resources/recipes/ArrowRecipe.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/Anchor.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/Stealth.tres"))

func addItem(item_name: String, count=1, unit=INVENTORY):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count, unit)

# BUG HERE !!
func addItemResource(item: ResItem, count=1, unit=INVENTORY, show_message=true):
	if !canAdd(item,count):
		return
	
	if item is ResStackItem and unit.has(item):
		unit[unit.find(item)].add(count)
	elif item is ResStackItem:
		print('grah')
		if item.STACK <= 0: item.STACK = 1
		item.add(count-1, false)
		unit.append(item)
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color] to %s.' % [item, getStorageUnitName(unit)])
	elif item is ResCharm:
		for i in range(count): unit.append(item.duplicate())
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color] to %s.' % [item, getStorageUnitName(unit)])
	else:
		unit.append(item)
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color] to %s.' % [item, getStorageUnitName(unit)])
	
	added_item_to_inventory.emit()
	unit.sort_custom(func sortByName(a, b): return a.NAME < b.NAME)

func hasItem(item_name, unit=INVENTORY):
	for item in unit:
		if item.NAME == item_name: return true
	
	return false

func getItem(item: ResItem, unit=INVENTORY):
	return unit[unit.find(item)]

func getItemWithName(item_name: String, unit=INVENTORY):
	for item in unit:
		if item.NAME == item_name:
			return item

func removeItemWithName(item_name: String, count=1, unit=INVENTORY, revoke_mandatory=false):
	for item in unit:
		if item.NAME == item_name:
			if revoke_mandatory: item.MANDATORY = false
			removeItemResource(item,count)

func removeItemResource(item, count=1, unit=INVENTORY, prompt=true):
	if count == 0:
		return
	elif item.MANDATORY:
		OverworldGlobals.getPlayer().prompt.showPrompt('Cannot remove [color=yellow]%s[/color]! Item is mandatory.' % [item])
		return
	
	if item is ResEquippable:
		if item.isEquipped(): item.unequip()
		unit.erase(item)
		if prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] removed from %s.' % [item, getStorageUnitName(unit)])
	
	elif item is ResStackItem:
		item.take(count)
		if !item is ResProjectileAmmo:
			if prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]x%s %s[/color] removed from %s.' % [count, item.NAME, getStorageUnitName(unit)])
		if item.STACK <= 0: 
			if prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] is depleted!' % [item.NAME])
			unit.erase(item)

func incrementStackItem(item_name: String, count):
	for item in INVENTORY:
		if item.NAME == item_name:
			item.add(count)
			added_item_to_inventory.emit()

func takeFromGhostStack(item: ResGhostStackItem, count, transfer_to_storage=false):
	if !canAdd(item.REFERENCE_ITEM, count, transfer_to_storage):
		return
	
	if hasItem(item.NAME):
		incrementStackItem(item.NAME, count)
	else:
		addItemResource(item.REFERENCE_ITEM, count)

func transferItem(item: ResItem, count: int, from: Array[ResItem], to: Array[ResItem]):
	if item is ResStackItem and count <= 0:
		return
	elif INVENTORY.has(item) and item.MANDATORY:
		return
	
	if from.has(item):
		removeItemResource(item, count, from, false)
		addItemResource(item, count, to)

func canAdd(item, count=1, transfer_storage=true, show_prompt=true):
	if (item is ResWeapon or item is ResUtilityCharm) and INVENTORY.has(item):
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	
	return true
#	if item is ResStackItem and count <= 0:
#		return

func getStorageUnitName(unit: Array[ResItem]):
	match unit:
		INVENTORY: return 'Inventory'

func getUnstackableItemNames()-> Array:
	var out = []
	
	for item in INVENTORY:
		if !item is ResStackItem:
			out.append(item.NAME)
	
	return out

func getRecipe(item: ResRecipe):
	return KNOWN_RECIPES[KNOWN_RECIPES.find(item)]

func repairItem(item: ResWeapon, repair_amount: int, free_repair=false):
	#if getItemWithName("Scrap Salvage") == null: 
	#	OverworldGlobals.getPlayer().prompt.showPrompt('Not enough [color=yellow]Scrap Salvage![/color]')
	if !free_repair and getItemWithName("Scrap Salvage").STACK >= repair_amount:
		removeItemWithName("Scrap Salvage", repair_amount)
		item.restoreDurability(repair_amount)
	elif free_repair:
		item.restoreDurability(repair_amount)
	else:
		OverworldGlobals.getPlayer().prompt.showPrompt('Not enough [color=yellow]Scrap Salvage![/color]')
		return

func repairAllItems():
	for item in INVENTORY:
		if !item is ResWeapon: continue
		item.restoreDurability(item.max_durability)

func saveData(save_data: Array):
	var data = InventorySaveData.new()
	data.INVENTORY = INVENTORY
	data.KNOWN_POWERS = KNOWN_POWERS
	data.KNOWN_RECIPES = KNOWN_RECIPES
	#data.STORAGE = STORAGE
	saveItemData(INVENTORY, data)
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	INVENTORY = save_data.INVENTORY
	KNOWN_POWERS = save_data.KNOWN_POWERS
	KNOWN_RECIPES = save_data.KNOWN_RECIPES
	loadItemData(INVENTORY, save_data)

func saveItemData(storage_unit: Array[ResItem], inv_save_data: InventorySaveData):
	var item_data: Dictionary
	if storage_unit == INVENTORY:
		item_data = inv_save_data.ITEM_DATA_INVENTORY
	else:
		item_data = inv_save_data.ITEM_DATA_STORAGE
	
	for item in storage_unit:
		if item is ResGhostStackItem:
			item_data[item.NAME] = [item.REFERENCE_ITEM.resource_path, item.STACK]
		elif item is ResStackItem:
			item_data[item.NAME] = item.STACK
		elif item is ResUtilityCharm:
			item_data[item.NAME] = item.equipped
		elif item is ResEquippable:
			item_data[item.NAME] = item.EQUIPPED_COMBATANT

func loadItemData(storage_unit: Array[ResItem], save_data: InventorySaveData):
	var item_data: Dictionary
	if storage_unit == INVENTORY:
		item_data = save_data.ITEM_DATA_INVENTORY
	else:
		item_data = save_data.ITEM_DATA_STORAGE
	
	for item in storage_unit:
		if item_data.keys().has(item.NAME):
			if item is ResGhostStackItem:
				continue
			elif item is ResStackItem:
				item.STACK = item_data[item.NAME]
			elif item is ResUtilityCharm:
				item.equipped = item_data[item.NAME]
			elif item is ResEquippable:
				item.EQUIPPED_COMBATANT = item_data[item.NAME]
