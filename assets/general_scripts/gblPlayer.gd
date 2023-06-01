extends Node

var INVENTORY = {}

func addItemToInventory(item_name: String):
	var item = load("res://assets/item_resources/itm"+item_name+".tres")
	if item is ResConsumable:
		if INVENTORY.has(item.NAME):
			INVENTORY[item.NAME].STACK += 1
		else:
			INVENTORY[item.NAME] = item
	elif item is ResWeapon or item is ResArmor:
		INVENTORY[item.NAME] = item
	print('Inv is now: ', INVENTORY)
	
