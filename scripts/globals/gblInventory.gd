extends Node

var INVENTORY: Array[ResItem] = []
var STORAGE: Array[ResItem] = []
var KNOWN_RECIPES: Array[ResRecipe] = []
var KNOWN_POWERS: Array[ResPower] = []
var CURRENT_CAPACITY = 0
var MAX_CAPACITY = 100
signal added_item_to_inventory

func _ready():
	KNOWN_RECIPES.append(load("res://resources/recipes/ArrowRecipe.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/Anchor.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/Stealth.tres"))

func addItem(item_name: String, count=1, unit=INVENTORY):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count, unit)

func addItemResource(item: ResItem, count=1, unit=INVENTORY, show_message=true):
	if unit == INVENTORY and !canAdd(item, count) or count <= 0:
		return
	
	if item is ResStackItem and unit.has(item):
		unit[unit.find(item)].add(count)
	elif item is ResStackItem:
		if item.STACK <= 0: item.STACK = 1
		item.add(count-1, false)
		unit.append(item)
	elif item is ResEquippable:
		unit.append(item)
	
	if show_message:
		OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color] to %s.' % [item, getStorageUnitName(unit)])
	
	if unit == INVENTORY: refreshWeights()
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

func removeItemResource(item, count=1, unit=INVENTORY):
	if count == 0:
		return
	elif item.MANDATORY:
		OverworldGlobals.getPlayer().prompt.showPrompt('Cannot remove [color=yellow]%s[/color]! Item is mandatory.' % [item])
		return
	
	if item is ResEquippable:
		if item.isEquipped(): item.unequip()
		unit.erase(item)
		OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] removed from %s.' % [item, getStorageUnitName(unit)])
	
	elif item is ResStackItem:
		item.take(count)
		if !item is ResProjectileAmmo:
			OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]x%s %s[/color] removed from %s.' % [count, item.NAME, getStorageUnitName(unit)])
		if item.STACK <= 0: 
			OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] is depleted!' % [item.NAME])
			unit.erase(item)
	
	if unit == INVENTORY: refreshWeights()

func refreshWeights():
	CURRENT_CAPACITY = 0
	for item in INVENTORY:
		CURRENT_CAPACITY += item.WEIGHT

func incrementStackItem(item_name: String, count):
	for item in INVENTORY:
		if item.NAME == item_name:
			item.add(count)
			added_item_to_inventory.emit()
			refreshWeights()

func createGhostStack(item: ResStackItem, count=1, transfer=true):
	for i in STORAGE:
		if i.NAME == item.NAME: 
			if transfer: removeItemResource(item, count)
			OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]x%s %s[/color] to Storage.' % [count, item.NAME])
			i.add(count, false)
			return
	
	var ghost_stack = ResGhostStackItem.new(item)
	if transfer: removeItemWithName(item.NAME, count)
	addItemResource(ghost_stack, count, STORAGE)

func takeFromGhostStack(item: ResGhostStackItem, count, transfer_to_storage=false):
	if !canAdd(item.REFERENCE_ITEM, count, transfer_to_storage):
		return
	
	for stackable in STORAGE:
		if stackable.NAME == item.NAME:
			removeItemResource(stackable,count,STORAGE)
	
	if hasItem(item.NAME):
		incrementStackItem(item.NAME, count)
	else:
		addItemResource(item.REFERENCE_ITEM, count)

func transferItem(item: ResItem, count: int, from: Array[ResItem], to: Array[ResItem]):
	if item is ResStackItem and count <= 0:
		return
	elif INVENTORY.has(item) and item.MANDATORY:
		return
	
	if item is ResStackItem and from == INVENTORY and to == STORAGE:
		createGhostStack(item, count)
		return
	elif item is ResStackItem and from == STORAGE and to == INVENTORY:
		takeFromGhostStack(item, count)
		return
	
	if from.has(item):
		removeItemResource(item, count, from)
		addItemResource(item, count, to)

func canAdd(item, count=1, transfer_storage=true, show_prompt=true):
	if item is ResEquippable and (hasItem(item.NAME) or hasItem(item.NAME, STORAGE)):
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	if item is ResEquippable and item.WEIGHT + CURRENT_CAPACITY > MAX_CAPACITY:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] not added! Your Inventory is full.' % item)
		if transfer_storage:
			addItemResource(item,1,STORAGE)
		return false
	
	if item is ResStackItem and count <= 0:
		return
	if item is ResStackItem and (item.PER_WEIGHT * count) + CURRENT_CAPACITY > MAX_CAPACITY:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]x%s %s[/color] not added! Your Inventory is full.' % [str(count), item.NAME])
		if transfer_storage:
			var feasible_count = determineFeasibleCount(item, count)
			addItemResource(item,feasible_count,INVENTORY)
			createGhostStack(item, count - feasible_count, false)
		return false	
	if item is ResStackItem and (item.STACK + count) > item.MAX_STACK:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Max stack for [color=yellow]%s[/color] reached!' % item.NAME)
		if transfer_storage:
			var feasible_count = item.MAX_STACK - item.STACK
			addItemResource(item,feasible_count,INVENTORY)
			createGhostStack(item, count - feasible_count, false)
		return false
	
	return true

func determineFeasibleCount(item: ResStackItem, count: int):
	while (item.PER_WEIGHT * count) + CURRENT_CAPACITY > MAX_CAPACITY:
		count -= 1
	
	return count

func getStorageUnitName(unit: Array[ResItem]):
	match unit:
		INVENTORY: return 'Inventory'
		STORAGE: return 'Storage'

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
	data.MAX_CAPACITY = MAX_CAPACITY
	data.INVENTORY = INVENTORY
	data.STORAGE = STORAGE.filter(func(item): return !item is ResStackItem)
	data.KNOWN_POWERS = KNOWN_POWERS
	data.KNOWN_RECIPES = KNOWN_RECIPES
	data.MAX_CAPACITY = MAX_CAPACITY
	#data.STORAGE = STORAGE
	saveItemData(INVENTORY, data)
	saveItemData(STORAGE, data)
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	MAX_CAPACITY = save_data.MAX_CAPACITY
	INVENTORY = save_data.INVENTORY
	STORAGE = save_data.STORAGE
	KNOWN_POWERS = save_data.KNOWN_POWERS
	KNOWN_RECIPES = save_data.KNOWN_RECIPES
	MAX_CAPACITY = save_data.MAX_CAPACITY
	#STORAGE = save_data.getStorage()
	loadItemData(INVENTORY, save_data)
	loadItemData(STORAGE, save_data)
	refreshWeights()

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
	
	if storage_unit == STORAGE:
		for item in item_data.keys():
			if item_data[item] is Array:
				var ghost_data: Array = item_data[item]
				var ghost_stack = ResGhostStackItem.new(load(ghost_data[0]))
				addItemResource(ghost_stack, ghost_data[1], STORAGE, false)
	
	for item in storage_unit:
		if item_data.keys().has(item.NAME):
			if item is ResGhostStackItem:
				continue
			elif item is ResStackItem:
				item.STACK = item_data[item.NAME]
				item.calcWeight()
			elif item is ResUtilityCharm:
				item.equipped = item_data[item.NAME]
			elif item is ResEquippable:
				item.EQUIPPED_COMBATANT = item_data[item.NAME]
