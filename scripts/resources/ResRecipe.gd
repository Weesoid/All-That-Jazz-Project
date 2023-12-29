extends Resource
class_name ResRecipe

@export var RECIPE: Dictionary
@export var OUTPUT: ResItem

func hasRequiredItems()-> bool:
	for ingridient in RECIPE:
		if InventoryGlobals.INVENTORY.has(ingridient) or InventoryGlobals.getUnstackableItemNames().has(ingridient.NAME):
			continue
		else:
			print('Missing: ', ingridient)
			print('False! No ingridients')
			return false
	
	for item in InventoryGlobals.INVENTORY:
		if item is ResStackItem and RECIPE.has(item):
			print(item)
			if item.STACK < RECIPE[item]:
				print('False! Not enough stacks')
				return false
	
	print('You can craft it!')
	return true

func craft():
	for item in RECIPE:
		if item is ResStackItem:
			InventoryGlobals.getItem(item).take(RECIPE[item])
		else:
			InventoryGlobals.removeItemWithName(item.NAME)
	
	InventoryGlobals.addItemResource(OUTPUT)

func getStringRecipe():
	var result = ""
	for key in RECIPE.keys():
		result += key.NAME.to_upper() + " x" + str(RECIPE[key]) + "\n"
	return result
