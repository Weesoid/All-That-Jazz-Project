extends Node

var INVENTORY: Array[ResItem] = []
var KNOWN_POWERS: Array[ResPower] = [preload("res://resources/powers/Anchor.tres"), preload("res://resources/powers/Stealth.tres")]
var RECIPES: Dictionary = {
	# In-game name -> .tres name
	['Scrap Salvage', null, null]: 'Arrow',
	['Arrow', 'Scrap Salvage', null]: 'ArrowSleeper',
	['Murder Charm', 'Scrap Salvage', null]: 'CharmStoneWall',
	['Scrap Salvage', 'Precious Salvage', null]: 'CharmMurder',
}

signal added_item_to_inventory

func addItem(item_name: String, count=1):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count, INVENTORY)

func getRecipeResult(item_name_array: Array, get_raw_string=false):
	var item = RECIPES[item_name_array].split('.')
	var output = [null, null]
	
	if !FileAccess.file_exists("res://resources/items/"+item[0]+".tres"):
		return null
	
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

func addItemResource(item: ResItem, count=1, show_message=true, check_restrictions=true):
	if (!canAdd(item,count) or count == 0) and check_restrictions:
		return
	
	if item is ResStackItem and INVENTORY.has(item):
		INVENTORY[INVENTORY.find(item)].add(count)
	elif item is ResStackItem:
		if item.STACK <= 0: item.STACK = 1
		item.add(count-1, false)
		INVENTORY.append(item)
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s (%s)[/color].' % [item.NAME, item.STACK])
	elif item is ResCharm:
		for i in range(count): 
			var dupe_item = item.duplicate()
			dupe_item.PARENT_ITEM = item
			INVENTORY.append(dupe_item)
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color].' % item)
	elif item is ResWeapon and check_restrictions:
		item.durability = item.max_durability
		INVENTORY.append(item)
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color].' % item)
	else:
		INVENTORY.append(item)
		if show_message: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color].' % item)
	
	added_item_to_inventory.emit()
	sortItems()

func hasItem(item_name, count:int=0):
	if item_name is String:
		for combatant in PlayerGlobals.TEAM:
			if combatant.EQUIPPED_WEAPON != null and combatant.EQUIPPED_WEAPON.NAME == item_name:
				return true
			for charm in combatant.CHARMS.values():
				if charm == null: 
					continue
				elif charm.NAME == item_name:
					return true
	elif item_name is ResItem:
		for combatant in PlayerGlobals.TEAM:
			if combatant.EQUIPPED_WEAPON == item_name:
				return true
			elif combatant.CHARMS.values().has(item_name):
				return true
	
	if item_name is String:
		for item in INVENTORY:
			if item is ResStackItem and count > 0 and item.STACK >= count and item.NAME == item_name:
				return true
			elif (item is ResStackItem and count <= 0) or !item is ResStackItem:
				return item.NAME == item_name
	elif item_name is ResItem:
		if count > 0 and INVENTORY.has(item_name) and getItem(item_name).STACK >= count:
			return true
		elif count <= 0:
			return INVENTORY.has(item_name)
	
	return false

func getEquippedWeapons()-> Array:
	var out = []
	for combatant in PlayerGlobals.TEAM:
		if combatant.EQUIPPED_WEAPON != null:
			out.append(combatant.EQUIPPED_WEAPON)
	return out

func getItem(item: ResItem):
	return INVENTORY[INVENTORY.find(item)]

func getItemWithName(item_name: String):
	for item in INVENTORY:
		if item.NAME == item_name:
			return item

func removeItemWithName(item_name: String, count=1, revoke_mandatory=false):
	for item in INVENTORY:
		if item.NAME == item_name:
			if revoke_mandatory: item.MANDATORY = false
			removeItemResource(item,count)

func removeItemResource(item, count=1, prompt=true, ignore_mandatory=false):
	if count == 0:
		return
	elif item.MANDATORY and !ignore_mandatory:
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
	if item is ResEquippable and hasItem(item):
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	elif item is ResStackItem and hasItem(item.NAME) and item.STACK + count > item.MAX_STACK and item.MAX_STACK > 0:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Adding x%s [color=yellow]%s[/color] would exceed the max stack.' % [count, item])
		return false
	
	return true

func calculateValidAdd(item: ResStackItem) -> int:
	if item is ResGhostStackItem:
		item = item.REFERENCE_ITEM
	
	if item.MAX_STACK == 0 and item.VALUE == 0:
		return 100
	
	if INVENTORY.has(item):
		if item.MAX_STACK - getItem(item).STACK > 0:
			return item.MAX_STACK - getItem(item).STACK
		else:
			return 0
	else:
		return item.MAX_STACK

func getUnstackableItemNames()-> Array:
	var out = []
	
	for item in INVENTORY:
		if !item is ResStackItem:
			out.append(item.NAME)
	
	return out

func repairItem(item: ResWeapon, repair_amount: int, free_repair=false):
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

func sortItems(items: Array[ResItem]=INVENTORY):
	items.sort_custom(
		func(a, b): 
			if  a is ResStackItem and b is ResStackItem:
				return a.STACK > b.STACK
			elif a is ResEquippable and b is ResEquippable:
				return getItemType(a) < getItemType(b)
			
			return getItemType(a) < getItemType(b)
			)
	#items.sort_custom(func(a, b): return a.NAME < b.NAME)

func getItemType(item: ResItem)-> float:
	if item is ResStackItem:
		if item is ResProjectileAmmo:
			return 0.2
		else:
			return 0.0
	elif item is ResEquippable:
		if item is ResWeapon:
			return 1.1
		elif item is ResCharm:
			return 1.2
		else:
			return 1.0
	
	return -1.0

func saveData(save_data: Array):
	var data = InventorySaveData.new()
	data.INVENTORY = INVENTORY
	data.KNOWN_POWERS = KNOWN_POWERS
	saveItemData(data)
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	INVENTORY = save_data.INVENTORY
	KNOWN_POWERS = save_data.KNOWN_POWERS
	loadItemData(save_data)

func saveItemData(inv_save_data: InventorySaveData):
	var item_data: Dictionary
	item_data = inv_save_data.ITEM_DATA_INVENTORY
	
	for item in INVENTORY:
		if item is ResGhostStackItem:
			item_data[item.resource_path] = [item.REFERENCE_ITEM.resource_path, item.STACK]
		elif item is ResStackItem:
			item_data[item.resource_path] = item.STACK
		elif item is ResWeapon:
			item_data[item.resource_path+'-durability'] = item.durability
	for weapon in getEquippedWeapons():
		item_data[weapon.resource_path+'-durability'] = weapon.durability

func loadItemData(save_data: InventorySaveData):
	var item_data: Dictionary
	item_data = save_data.ITEM_DATA_INVENTORY
	
	for item in INVENTORY:
		if item_data.keys().has(item.resource_path):
			if item is ResGhostStackItem:
				continue
			elif item is ResStackItem:
				item.STACK = item_data[item.resource_path]
		if item is ResWeapon and item_data.keys().has(item.resource_path+'-durability'):
			item.durability = item_data[item.resource_path+'-durability']
	for weapon in getEquippedWeapons():
		weapon.durability = item_data[weapon.resource_path+'-durability']
