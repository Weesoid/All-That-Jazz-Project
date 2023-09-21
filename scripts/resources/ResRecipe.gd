extends Resource
class_name ResRecipe

@export var RECIPE: Dictionary
@export var OUTPUT: ResItem

func hasRequiredItems()-> bool:
	for ingridient in RECIPE:
		if PlayerGlobals.INVENTORY.has(ingridient) or PlayerGlobals.getUnstackableItemNames().has(ingridient.NAME):
			continue
		else:
			print('Missing: ', ingridient)
			print('False! No ingridients')
			return false
	
	for item in PlayerGlobals.INVENTORY:
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
			PlayerGlobals.getItem(item).take(RECIPE[item])
		else:
			PlayerGlobals.removeItemWithName(item.NAME)
	
	PlayerGlobals.addItemResource(OUTPUT)

func getStringRecipe():
	var result = ""
	for key in RECIPE.keys():
		result += key.NAME.to_upper() + " x" + str(RECIPE[key]) + "\n"
	return result
