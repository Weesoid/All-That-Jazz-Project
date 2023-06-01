extends Node

var INVENTORY = {}

func addItemToInventory(item_name: String):
	var item = load("res://assets/item_resources/itm"+item_name+".tres")
	if item is ResItem or item is ResConsumable:
		if INVENTORY.has(item.NAME):
			INVENTORY[item.NAME].STACK += 1
		else:
			INVENTORY[item.NAME] = item
	else:
		INVENTORY[item.NAME] = item
	print('Inv is now: ', INVENTORY)
	
