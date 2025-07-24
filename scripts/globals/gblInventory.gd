extends Node

var inventory: Array[ResItem] = []
var crafted_items: Array[String] = []
var recipes: Dictionary = {
	# In-game name -> .tres name
	['Scrap Salvage', null, null]: 'ArrowJunk.8',
	['Junk Arrow', 'Scrap Salvage', null]: 'Arrow.2',
	['Arrow', 'Scrap Salvage', null]: 'ArrowSleeper',
	['Murder Charm', 'Scrap Salvage', null]: 'CharmStoneWall',
	['Scrap Salvage', 'Precious Salvage', null]: 'CharmMurder',
}
var max_inventory: int = 200

signal added_item_to_inventory

func loadItemResource(resource_name: String)-> ResItem:
	return load("res://resources/items/"+resource_name+".tres")

func addItem(item_name: String, count=1):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count, inventory)

func getRecipeResult(item_name_array: Array, get_raw_string=false):
	var item = recipes[item_name_array].split('.')
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
			out[i] = item_array[i].name
	
	if recipes.has(out):
		var craft_data = recipes[out].split('.')
		if craft_data.size() > 1:
			addItem(craft_data[0], int(craft_data[1]))
		else:
			addItem(craft_data[0])
		if !crafted_items.has(craft_data[0]):
			crafted_items.append(craft_data[0])

func addItemResource(item: ResItem, count=1, show_message=true, check_restrictions=true):
	if (!canAdd(item,count,show_message) or count == 0) and check_restrictions:
		return
	
	if item is ResStackItem and inventory.has(item):
		inventory[inventory.find(item)].add(count)
	elif item is ResStackItem:
		if item.stack <= 0: item.stack = 1
		item.add(count-1, false)
		inventory.append(item)
		if show_message: OverworldGlobals.showPrompt('Added [color=yellow]%s (%s)[/color].' % [item.name, item.stack])
	elif item is ResCharm:
		for i in range(count): 
			var dupe_item = item.duplicate()
			if item.parent_item != '':
				dupe_item.parent_item = item.parent_item
			else:
				dupe_item.parent_item = item.resource_path
			dupe_item.removeEmptyModifications()
			inventory.append(dupe_item)
		if show_message: OverworldGlobals.showPrompt('Added [color=yellow]%s[/color].' % item)
	elif item is ResWeapon and check_restrictions:
		item.durability = item.max_durability
		inventory.append(item)
		if show_message: OverworldGlobals.showPrompt('Added [color=yellow]%s[/color].' % item)
	else:
		inventory.append(item)
		if show_message: OverworldGlobals.showPrompt('Added [color=yellow]%s[/color].' % item)
	
	added_item_to_inventory.emit()
	sortItems()

func giveItemDict(item_dict:Dictionary):
	for item in item_dict.keys():
		if item is ResStackItem:
			addItemResource(item, item_dict[item])
		else:
			for i in range(item_dict[item]): 
				addItemResource(item)

func hasItem(item_name, count:int=0, check_equipped:bool=true):
	if item_name is String and check_equipped:
		for combatant in PlayerGlobals.team:
			if combatant.equipped_weapon != null and combatant.equipped_weapon.name == item_name:
				return true
			for charm in combatant.charms.values():
				if charm == null: 
					continue
				elif charm.name == item_name:
					return true
	elif item_name is ResItem and check_equipped:
		for combatant in PlayerGlobals.team:
			if combatant.equipped_weapon == item_name:
				return true
			elif combatant.charms.values().has(item_name):
				return true
	
	if item_name is String:
		for item in inventory:
			if item is ResStackItem and count > 0 and item.stack >= count and item.name == item_name:
				return true
			elif (item is ResStackItem and count <= 0) or (!item is ResStackItem):
				if item.name == item_name:
					return true
				else:
					continue
	elif item_name is ResItem:
		if count > 0 and inventory.has(item_name) and getItem(item_name).stack >= count:
			return true
		elif count <= 0:
			return inventory.has(item_name)
	
	return false

func getEquippedWeapons()-> Array:
	var out = []
	for combatant in PlayerGlobals.team:
		if combatant.equipped_weapon != null:
			out.append(combatant.equipped_weapon)
	return out

func getItem(item):
	if item is ResItem:
		return inventory[inventory.find(item)]
	elif item is String:
		return getItemWithName(item)

func getItemWithName(item_name: String):
	for item in inventory:
		if item.name == item_name:
			return item

func removeItemWithName(item_name: String, count=1, revoke_mandatory=false):
	for item in inventory:
		if item.name == item_name:
			if revoke_mandatory: item.mandatory = false
			removeItemResource(item,count)

func removeItemResource(item, count=1, prompt=true, ignore_mandatory=false):
	if count == 0:
		return
	elif item.mandatory and !ignore_mandatory:
		OverworldGlobals.showPrompt('Cannot remove [color=yellow]%s[/color]! Item is mandatory.' % [item])
		return
	
	if item is ResEquippable:
		if item.isEquipped(): item.unequip()
		inventory.erase(item)
		if prompt: OverworldGlobals.showPrompt('[color=yellow]%s[/color] removed.' % item)
	
	elif item is ResStackItem:
		item.take(count)
		if !item is ResProjectileAmmo:
			if prompt: OverworldGlobals.showPrompt('[color=yellow]x%s %s[/color] removed.' % [count, item.name])
		if item.stack <= 0: 
			if prompt: OverworldGlobals.showPrompt('[color=yellow]%s[/color] is depleted!' % [item.name])
			inventory.erase(item)

func incrementStackItem(item_name: String, count):
	for item in inventory:
		if item.name == item_name:
			item.add(count)
			added_item_to_inventory.emit()

func takeFromGhostStack(item: ResGhostStackItem, count):
	if !canAdd(item.reference_item, count) or count <= 0:
		return
	
	if hasItem(item.name):
		incrementStackItem(item.name, count)
	else:
		addItemResource(item.reference_item, count)

func canAdd(item, count:int=1, show_prompt=true):
	if inventory.size() >= max_inventory:
		if show_prompt: OverworldGlobals.showPrompt('[color=pink]You canot have more than %s items. How did you even manage this?[/color]' % max_inventory, 15)
		return false
	elif item is ResEquippable and hasItem(item):
		if show_prompt: OverworldGlobals.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	elif item is ResStackItem and hasItem(item.name) and item.stack == item.max_stack and item.max_stack > 0:
		if show_prompt: OverworldGlobals.showPrompt('Adding x%s [color=yellow]%s[/color] would exceed the max stack.' % [count, item])
		return false
	
	return true

func calculateValidAdd(item: ResStackItem) -> int:
	if item is ResGhostStackItem:
		item = item.reference_item
	
	if item.max_stack == 0 and item.value == 0:
		return 100
	
	if inventory.has(item):
		if item.max_stack - getItem(item).stack > 0:
			return item.max_stack - getItem(item).stack
		else:
			return 0
	else:
		return item.max_stack

func getUnstackableItemNames()-> Array:
	var out = []
	
	for item in inventory:
		if !item is ResStackItem:
			out.append(item.name)
	
	return out

func repairItem(item: ResWeapon, repair_amount: int, free_repair=false):
	if !free_repair and getItemWithName("Scrap Salvage").stack >= repair_amount:
		removeItemWithName("Scrap Salvage", repair_amount)
		item.restoreDurability(repair_amount)
	elif free_repair:
		item.restoreDurability(repair_amount)
	else:
		OverworldGlobals.showPrompt('Not enough [color=yellow]Scrap Salvage![/color]')
		return

func repairAllItems(only_active_members: bool=false):
	for member in OverworldGlobals.getCombatantSquad('Player'):
		if member.hasEquippedWeapon(): 
			var weapon = member.equipped_weapon
			weapon.restoreDurability(weapon.max_durability)
	if only_active_members: return
	for item in inventory:
		if !item is ResWeapon: continue
		item.restoreDurability(item.max_durability)

func sortItems(items: Array[ResItem]=inventory):
	items.sort_custom(
		func(a, b):
			if a is ResStackItem and b is ResStackItem:
				return a.stack > b.stack
			elif a is ResEquippable and b is ResEquippable:
				return getItemType(a) < getItemType(b)
			
			return getItemType(a) < getItemType(b)
			)
	#items.sort_custom(func(a, b): return a.name < b.name)

func getItemType(item: ResItem)-> float:
	if item is ResStackItem:
		if item is ResProjectileAmmo:
			return 0.1
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
	data.inventory = inventory
	data.crafted_items = crafted_items
	saveItemData(data)
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	inventory = save_data.inventory
	crafted_items = save_data.crafted_items
	loadItemData(save_data)

func saveItemData(inv_save_data: InventorySaveData):
	var item_data: Dictionary
	item_data = inv_save_data.item_data_inventory
	
	for item in inventory:
		if item is ResGhostStackItem:
			item_data[item.resource_path] = [item.reference_item.resource_path, item.stack]
		elif item is ResStackItem:
			item_data[item.resource_path] = item.stack
		elif item is ResWeapon:
			item_data[item.resource_path+'-durability'] = item.durability
	for weapon in getEquippedWeapons():
		item_data[weapon.resource_path+'-durability'] = weapon.durability

func loadItemData(save_data: InventorySaveData):
	var item_data: Dictionary
	item_data = save_data.item_data_inventory
	
	for item in inventory:
		if item_data.keys().has(item.resource_path):
			if item is ResGhostStackItem:
				continue
			elif item is ResStackItem:
				item.stack = item_data[item.resource_path]
				if item.stack > item.max_stack: item.stack = item.max_stack
		if item is ResWeapon and item_data.keys().has(item.resource_path+'-durability'):
			item.durability = item_data[item.resource_path+'-durability']
		elif item is ResCharm:
			item.updateItem()
	for weapon in getEquippedWeapons():
		weapon.durability = item_data[weapon.resource_path+'-durability']

func resetVariables():
	inventory = []
	crafted_items = []
