extends Resource
class_name InventorySaveData

@export var inventory: Dictionary
@export var crafted_items: Array[String]

func saveInventory(p_inventory: Array[ResItem]):
	for item in p_inventory:
		if item is ResStackItem:
			inventory[item.resource_path] = item.stack
		elif item is ResWeapon:
			inventory[item.resource_path] = item.durability
		elif item is ResCharm:
			inventory[item.parent_item] = item.parent_item

func loadInventory():
	var out_inventory = []
	
	for item_path in inventory.keys():
		if !FileAccess.file_exists(item_path): continue
		
		var item = load(item_path)
		if item is ResStackItem:
			item.stack = inventory[item_path]
		elif item is ResWeapon:
			item.durability = inventory[item_path]
		elif item is ResCharm:
			item.parent_item = inventory[item_path]
			item.updateItem()
		
		out_inventory.append(item)
	
	return out_inventory
