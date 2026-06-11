extends Node

var inventory: Array[ResItem] = [] # Marked for indirect reference. Load per item, skip if !file_exists.
var crafted_items: Array[String] = []
var recipes: Dictionary = {
	# .tres name -> .tres name
	'Arrow.2':{'ScrapSalvage': 1, 'Wood':1},
	'Rations':{'CharmMurder': 1, 'ScrapSalvage': 1},
	'CharmMurder':{'ScrapSalvage': 12, 'ArrowJunk': 16,'ArrowSleeper':1},
	'RushDown':{'CritRations': 1, 'ExtraRations': 1,'Rations':1, 'ScrapSalvage':1},
	'ScrapSalvage.1':{'ArrowJunk': 1},
	'Kindling':{'Wood':1,'WhittlingKnife':1}
}
var max_inventory: int = 1000
var duplicate_charm_cap:int=50

signal removed_item_from_inventory(item)
signal item_equipped(item)
signal added_item_to_inventory(item, amount)
signal stack_item_changed(item, change_amount)
signal item_repaired(weapon, new_durability)
signal item_used(item)
signal recipe_added(item_recipe)

func loadItemResource(resource_name: String)-> ResItem:
	assert(FileAccess.file_exists("res://resources/items/"+resource_name+".tres"), 'Item %s in path "res://resources/items/%s.tres" does not exist!' % [resource_name, resource_name])
	return load("res://resources/items/"+resource_name+".tres")

func addItem(item_name: String, count:int=1, show_message:bool=true):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item '%s' not found!" % item_name)
	addItemResource(item, count,show_message)

## Returns [ItemResource, Craft Count] e.g. ["ScrapSalvage", 3]
func getRecipeResult(input_recipe)-> Array:
	input_recipe.sort()
	
	for crafted_item in recipes.keys():
		var check_recipe = recipes[crafted_item].keys()
		check_recipe.sort()
		if input_recipe != check_recipe: continue
		var output = crafted_item.split('.')
		print(output)
		if output.size() > 1 and output[1] == 'repair':
			return [output[0],1,'is_repair_recipe']
		else:
			return [output[0],int(output[1])] if output.size() == 2 else [output[0],1]
	
	return []

func getCraftCount(item_filename:String)->int:
	for key in recipes.keys():
		var result_data = key.split('.')
		if result_data[0] == item_filename:
			return int(result_data[1]) if result_data.size() > 1 else 1
	
	return -1

func getRecipe(for_item: ResItem)->Dictionary:
	for result in recipes.keys():
		if result.split('.')[0] == for_item.getFilename():
			return recipes[result]
	return {}

func craftItem(item_to_craft:ResItem, count:int=1):
	var craft_result = getRecipeResult(getRecipe(item_to_craft).keys())
	if !canCraft(item_to_craft):
		return false
	
	var recipe = getRecipe(item_to_craft)
	for item_filename in recipe:
		var item = loadItemResource(item_filename)
		if item is ResCraftingTool and !item.isBroken():
			item.useDurability(count)
		elif !item is ResCraftingTool:
			removeItemResource(item,recipe[item_filename]*count,false)
	
	addItem(craft_result[0],int(craft_result[1])*count)
	if !crafted_items.has(craft_result[0]):
		crafted_items.append(craft_result[0])
		recipe_added.emit(craft_result[0])

func canCraft(item:ResItem, craft_count:int=1):
	var recipe = getRecipe(item)
	var count = getRecipeResult(recipe.keys())[1]
	if recipe.is_empty() or !canAdd(item,count,false):
		return false
	
	for material in recipe:
		var loaded_material = loadItemResource(material)
		if !hasItem(material, recipe[material]*craft_count) or (loaded_material is ResCraftingTool and loaded_material.durability < craft_count):
			return false
	
	return true

func getMaxCrafts(item: ResItem, is_repair:bool=false):
	if is_repair and hasItem(item.repair_item, item.max_durability - item.durability):
		return item.max_durability-item.durability
	elif getRecipe(item).is_empty() or !canCraft(item):
		return null
	
	var recipe = getRecipe(item)
	var bottleneck:ResItem
	var bottleneck_max_craft = 9999
	for material_filename in recipe:
		var material_cost = recipe[material_filename]
		var material = loadItemResource(material_filename)
		print(material , ' is crafting tool? ', material is ResCraftingTool)
		var max_c = material.durability if material is ResCraftingTool else getItemCount(material) / material_cost
		if max_c < bottleneck_max_craft:
			bottleneck = material
			bottleneck_max_craft = max_c
	
	var max_crafts = bottleneck.durability if bottleneck is ResCraftingTool else int(getItemCount(bottleneck) / recipe[bottleneck.getFilename()])
	if item is ResStackItem:
		var max_stack = (item.max_stack / getCraftCount(item.getFilename())) - (getItemCount(item) / getCraftCount(item.getFilename()))
		return min(max_crafts, max_stack)
	else:
		return max_crafts

func addAllRepairRecipes():
	var all_repairables = inventory.filter(func(item): return item.isRepairable())
	var equipped_weapons = getEquippedWeapons()
	all_repairables.append_array(equipped_weapons)
	
	for item in all_repairables:
		addRepairRecipe(item)

func addRepairRecipe(item:ResItem):
	recipes[item.getFilename()+'.repair'] = {item.getFilename():1, item.repair_item.getFilename(): item.repair_cost}

func getRepairRecipes():
	var out = {}
	var repair_recipe_keys = recipes.keys().filter(func(key): return key.contains('.repair'))
	for key in repair_recipe_keys:
		out[key] = recipes[key]
	return out

func getItemCount(item:ResItem, count_equipped:bool=true):
	var append_count=0
	if item is ResStackItem:
		return item.stack if hasItem(item) else 0
	elif item is ResWeapon and count_equipped:
		append_count = getEquippedWeapons().count(item)
	elif item is ResCharm and count_equipped:
		append_count = getEquippedCharms().count(item)
	
	return inventory.filter(func(itm): return itm.getFilename() == item.getFilename()).size()+append_count

#func itemInRecipe(item:ResItem, recipe):
#	for 

func addItemResource(item: ResItem, count:int=1, show_message:bool=true, check_restrictions=true):
	if (!canAdd(item,count,show_message) or count == 0) and check_restrictions:
		return
	
	if item is ResStackItem and inventory.has(item):
		if item.stack+count > item.max_stack: count = item.max_stack-item.stack
		inventory[inventory.find(item)].add(count, show_message)
	elif item is ResStackItem:
		if item.stack <= 0: item.stack = 1
		item.add(count-1, false)
		inventory.append(item)
	
	elif item is ResCharm:
		for i in range(count): inventory.append(item)
	
	elif item.isRepairable() and check_restrictions:
		item.durability = item.max_durability
		inventory.append(item)
		addRepairRecipe(item)
	
	else:
		inventory.append(item)
	
#	if item is ResStackItem and show_message: 
#		OverworldGlobals.showPrompt('Added [color=yellow]%s (%s)[/color].' % [item.name, item.stack])
#	elif show_message: 
#		OverworldGlobals.showPrompt('Added [color=yellow][img]' + item.icon.resource_path+'[/img] '+item.name)
	
	added_item_to_inventory.emit(item, count)
	sortItems()

func giveItemDict(item_dict:Dictionary,show_message:bool=true):
	for item in item_dict.keys():
		if item is ResStackItem:
			addItemResource(item, item_dict[item],show_message)
		else:
			for i in range(item_dict[item]): 
				addItemResource(item,1,show_message)

func hasItem(item_key, count:int=1, check_equipped:bool=true)-> bool:
	assert(item_key is ResItem or item_key is String, 'Cannot check "%s" for it is not an item.' % item_key)
	var find_item: ResItem
	if item_key is String:
		assert(FileAccess.file_exists("res://resources/items/%s.tres" % item_key), 'Path to %s item does not exist!' % item_key)
		find_item = load("res://resources/items/%s.tres" % item_key)
	elif item_key is ResItem:
		find_item = item_key
	else:
		assert(true, 'Unknown item key type: %s'%item_key)
	
	if find_item is ResEquippable and check_equipped:
		for member in PlayerGlobals.team:
			if find_item is ResWeapon and member.hasWeapon(find_item):
				return true
			elif find_item is ResCharm and member.hasCharm(find_item):
				return true
	
	if find_item is ResStackItem:
		var stack_items: Array = inventory.filter(func(item): return item is ResStackItem)
		return stack_items.has(find_item) and stack_items[stack_items.find(find_item)].stack >= count
	elif find_item is ResCharm:
		return getCharms(find_item).size() >= count
	
	return inventory.has(find_item)

func getCharms(charm:ResCharm)-> Array:
	var parent_charm = load("res://resources/items/%s.tres"%charm.getFilename())
	return inventory.filter(func(item): return item == charm)

func getEquippedWeapons()-> Array:
	var out = []
	for combatant in PlayerGlobals.team:
		if combatant.hasEquippedWeapon(): 
			out.append(combatant.equipped_weapon)
	return out

func getEquippedCharms()-> Array:
	var out = []
	for combatant in PlayerGlobals.team:
		for charm in combatant.charms.values():
			if charm != null: out.append(charm)
	
	return out

func getNonMandatoryItems():
	return inventory.filter(func(item): return !item.mandatory)

func getItem(item):
	if item is ResCharm:
		return getCharms(item)[0]
	elif item is ResItem:
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
		#OverworldGlobals.showPrompt('Cannot remove [color=yellow]%s[/color]! Item is mandatory.' % [item])
		return
	
	if item is ResCharm:
		for i in range(count):
			inventory.erase(getCharms(item)[0])
		#if prompt: OverworldGlobals.showPrompt('%sx [color=yellow]%s[/color] were removed.' % [count, item])
	elif item is ResEquippable:
		inventory.erase(item)
		#if prompt: OverworldGlobals.showPrompt('[color=yellow]%s[/color] removed.' % item)
	elif item is ResStackItem:
		item.take(count)
#		if !item is ResProjectileAmmo:
#			if prompt: OverworldGlobals.showPrompt('[color=yellow]x%s %s[/color] removed.' % [count, item.name])
		if item.stack <= 0: 
			#if prompt: OverworldGlobals.showPrompt('[color=yellow]%s[/color] is depleted!' % [item.name])
			inventory.erase(item)
	else:
		inventory.erase(item)
	
	if !hasItem(item) or item is ResCharm:
		removed_item_from_inventory.emit(item)

func incrementStackItem(item_name: String, count):
	for item in inventory:
		if item.name == item_name:
			item.add(count)
			added_item_to_inventory.emit(item, count)

func takeFromGhostStack(item: ResGhostStackItem, count):
	if !canAdd(item.reference_item, count) or count <= 0:
		return
	
	if hasItem(item):
		incrementStackItem(item.name, count)
	else:
		addItemResource(item.reference_item, count)

func canAdd(item, count:int=1, show_prompt=true):
	if inventory.size() >= max_inventory:
		if show_prompt: OverworldGlobals.showPrompt('You canot have more than [color=yellow]%s[/color] items. How did you even manage this?' % max_inventory,10)
		return false
	elif item is ResCharm and getItemCount(item)+count>duplicate_charm_cap:
		if show_prompt: OverworldGlobals.showPrompt("Already have enough [color=yellow]%s%s[/color]." % ['[img]'+item.icon.resource_path+'[/img] ',item.name])
		return false
	elif (item is ResWeapon or item is ResCraftingTool) and hasItem(item):
		#if show_prompt: OverworldGlobals.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	elif item is ResStackItem and hasItem(item) and item.stack == item.max_stack and item.max_stack > 0:
		#if show_prompt: OverworldGlobals.showPrompt('Adding x%s [color=yellow]%s[/color] would exceed the max stack.' % [count, item])
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
	elif item is ResCraftingTool:
		return 0.2
	
	return -1.0

# TODO: Update proof removaal of recipes
func isRecipeValid(item:String)->bool:
	if !FileAccess.file_exists("res://resources/items/%s.tres" % item) or !recipeExists(item):
		return false
	
	for material in findRecipe(item):
		if !FileAccess.file_exists("res://resources/items/%s.tres" % item):
			return false
	
	return true

func recipeExists(item:String):
	for recipe_item in recipes.keys():
		if recipe_item.split('.')[0] == item: return true
	
	return false

func findRecipe(item:String):
	for recipe_item in recipes.keys():
		if recipe_item.split('.')[0] == item: return recipes[recipe_item]
	
	return null

func saveData(save_data: Array):
	var data = InventorySaveData.new()
	data.saveInventory(inventory)
	data.crafted_items = crafted_items
	save_data.append(data)

func loadData(save_data: InventorySaveData):
	inventory.assign(save_data.loadInventory())
	crafted_items = save_data.crafted_items.filter(func(item): return isRecipeValid(item))
	#addAllRepairRecipes()

func resetVariables():
	inventory = []
	crafted_items = []
