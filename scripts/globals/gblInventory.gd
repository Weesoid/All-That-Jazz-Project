extends Node

var inventory: Array[ResItem] = [] # Marked for indirect reference. Load per item, skip if !file_exists.
var crafted_items: Array[String] = []
var recipes: Dictionary = {
	# .tres name -> .tres name
	{'ScrapSalvage': 1}: 'ArrowJunk.8',
	{'ArrowJunk': 1, 'ScrapSalvage': 2}: 'Arrow.2',
	{'Arrow': 1, 'ScrapSalvage': 1,'CharmMurder':1}: 'ArrowSleeper.1',
	{'MurderCharm': 1, 'ScrapSalvage': 1}: 'CharmStoneWall.1',
	{'ScrapSalvage': 12, 'ArrowJunk': 16,'ArrowSleeper':1}: 'CharmMurder.1',
}
var max_inventory: int = 500

signal added_item_to_inventory
signal stack_item_changed(item, new_stack, old_stack)

func loadItemResource(resource_name: String)-> ResItem:
	return load("res://resources/items/"+resource_name+".tres")

func addItem(item_name: String, count:int=1, show_message:bool=true):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count,show_message)

func canCraft(item_filename: String):
	var recipe = getItemRecipe(item_filename)
	for component in recipe.keys():
		var item = load("res://resources/items/%s.tres"%component)
		var count = recipe[component]
		if !InventoryGlobals.hasItem(item,count):
			return false
	
	return true

func getItemRecipe(item_filename:String)-> Dictionary:
	var craftables = recipes.values()
	var recipe_idx:int = -1
	
	for i in range(recipes.values().size()):
		if craftables[i].split('.')[0] == item_filename:
			recipe_idx = i
			break
	
	return recipes.keys()[recipe_idx]

## Returns [ItemResource, Craft Count] e.g. [ScrapSalvage, 3]
func getRecipeResult(recipe):
	var recipe_key
	if recipe is Array:
		recipe = recipe.filter(func(item_filename): return item_filename != '')
		if !getBaseRecipes().has(recipe):
			return null
		recipe_key = getRecipeFromBase(recipe)
	elif recipe is Dictionary:
		if !recipes.keys().has(recipe):
			return null
		recipe_key = recipe
	
	var result_filename = recipes[recipe_key].split('.')
	return [load("res://resources/items/%s.tres" % result_filename[0]), int(result_filename[1])]

func getCraftCount(item):
	for rec in recipes.keys():
		if recipes[rec].split('.')[0] == item:
			return recipes[rec].split('.')[1]

func craftItem(base_recipe: Array):
	base_recipe = base_recipe.filter(func(item_filename): return item_filename != '')
	assert(getBaseRecipes().has(base_recipe), 'Recipe: %s not found!' % str(base_recipe))
	if !canCraft(getRecipeResult(base_recipe)[0].getFilename()):
		return
	
	var recipe = getRecipeFromBase(base_recipe)
	var craft_data = recipes[recipe].split('.')
	addItem(craft_data[0], int(craft_data[1]),false)
	
	if !crafted_items.has(craft_data[0]):
		crafted_items.append(craft_data[0])
	
	for item_filepath in recipe.keys():
		var item = load("res://resources/items/%s.tres" % item_filepath)
		var count = recipe[item_filepath]
		InventoryGlobals.removeItemResource(item, count, false)

func getBaseRecipes()->Array:
	var base_recipes = []
	
	for recipe in recipes.keys():
		base_recipes.append(recipe.keys())
	
	return base_recipes

func getRecipeFromBase(base_recipe:Array)-> Dictionary:
	return recipes.keys()[getBaseRecipes().find(base_recipe)]

func addItemResource(item: ResItem, count:int=1, show_message:bool=true, check_restrictions=true):
	if (!canAdd(item,count,show_message) or count == 0) and check_restrictions:
		return
	
	if item is ResStackItem and inventory.has(item):
		inventory[inventory.find(item)].add(count, show_message)
	
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

func giveItemDict(item_dict:Dictionary,show_message:bool=true):
	for item in item_dict.keys():
		if item is ResStackItem:
			addItemResource(item, item_dict[item],show_message)
		else:
			for i in range(item_dict[item]): 
				addItemResource(item,1,show_message)

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

func getNonMandatoryItems():
	return inventory.filter(func(item): return !item.mandatory)

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
	elif item is ResWeapon and hasItem(item):
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
	data.saveInventory(inventory)
	data.crafted_items = crafted_items
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	inventory.assign(save_data.loadInventory())
	crafted_items = save_data.crafted_items

func resetVariables():
	inventory = []
	crafted_items = []
