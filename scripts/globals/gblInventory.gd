extends Node

var INVENTORY: Array[ResItem] = []
var KNOWN_POWERS: Array[ResPower] = [preload("res://resources/powers/Anchor.tres"), preload("res://resources/powers/Stealth.tres")]
var RECIPES: Dictionary = {
	# In-game name -> .tres name
	['Scrap Salvage', null, null]: 'Arrow',
	['Arrow', 'Scrap Salvage', null]: 'ArrowSleeper',
	['Murder Charm', 'Scrap Salvage', null]: 'BowStone'
}

signal added_item_to_inventory

func addItem(item_name: String, count=1, unit=INVENTORY):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count, unit)

func getRecipeResult(item_name_array: Array, get_raw_string=false):
	var item = RECIPES[item_name_array].split('.')
	var output = [null, null]
	
	if get_raw_string:
		output[0] = load("res://resources/items/"+item[0]+".tres")
		if item.size() > 1: output[1] = int(item[1])
		return output
	else:
		return load("res://resources/items/"+item[0]+".tres")

func craftItem(item_array: Array[ResItem]):
	var out = [null, null, null]
	for i in range(item_array.size()):
		if item_array[i] != null:
			out[i] = item_array[i].NAME
	
	if RECIPES.has(out):
		var craft_data = RECIPES[out].split('.')
		if craft_data.size() > 1:
			addItem(craft_data[0], int(craft_data[1]))
		else:
			addItem(craft_data[0])

func addItemResource(item: ResItem, count=1, unit=INVENTORY, show_message=true):
	if !canAdd(item,count) or count == 0:
		return
	
	if item is ResStackItem and unit.has(item):
		unit[unit.find(item)].add(count)
	elif item is ResStackItem:
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

func hasItem(item_name):
	if item_name is String:
		for item in INVENTORY:
			if item.NAME == item_name: return true
	elif item_name is ResItem:
		return INVENTORY.has(item_name)
	
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

func removeItemResource(item, count=1, prompt=true):
	if count == 0:
		return
	elif item.MANDATORY:
		OverworldGlobals.getPlayer().prompt.showPrompt('Cannot remove [color=yellow]%s[/color]! Item is mandatory.' % [item])
		return
	
	if item is ResEquippable:
		if item.isEquipped(): item.unequip()
		INVENTORY.erase(item)
		if prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] removed.' % item)
	
	elif item is ResStackItem:
		item.take(count)
		if !item is ResProjectileAmmo:
			if prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]x%s %s[/color] removed.' % [count, item.NAME])
		if item.STACK <= 0: 
			if prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] is depleted!' % [item.NAME])
			INVENTORY.erase(item)

func incrementStackItem(item_name: String, count):
	for item in INVENTORY:
		if item.NAME == item_name:
			item.add(count)
			added_item_to_inventory.emit()

func takeFromGhostStack(item: ResGhostStackItem, count):
	if !canAdd(item.REFERENCE_ITEM, count) or count <= 0:
		return
	
	if hasItem(item.NAME):
		incrementStackItem(item.NAME, count)
	else:
		addItemResource(item.REFERENCE_ITEM, count)

func canAdd(item, count:int=1, show_prompt=true):
	if (item is ResWeapon or item is ResUtilityCharm) and INVENTORY.has(item):
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	elif item is ResStackItem and hasItem(item.NAME) and item.STACK + count > item.MAX_STACK and item.MAX_STACK > 0:
		print('cannot add this stack item')
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Adding x%s [color=yellow]%s[/color] would exceed the max stack.' % [count, item])
		return false
	
	
	return true
#	if item is ResStackItem and count <= 0:
#		return

func calculateValidAdd(item: ResStackItem) -> int:
	if item is ResGhostStackItem:
		item = item.REFERENCE_ITEM
	
	if item.MAX_STACK == 0:
		return 100
	
	if INVENTORY.has(item):
		if item.MAX_STACK - getItem(item).STACK > 0:
			return item.MAX_STACK - getItem(item).STACK
		else:
			return 0
	else:
		return item.MAX_STACK

func getStorageUnitName(unit: Array[ResItem]):
	match unit:
		INVENTORY: return 'Inventory'

func getUnstackableItemNames()-> Array:
	var out = []
	
	for item in INVENTORY:
		if !item is ResStackItem:
			out.append(item.NAME)
	
	return out

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
	#data.STORAGE = STORAGE
	saveItemData(INVENTORY, data)
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	INVENTORY = save_data.INVENTORY
	KNOWN_POWERS = save_data.KNOWN_POWERS
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
