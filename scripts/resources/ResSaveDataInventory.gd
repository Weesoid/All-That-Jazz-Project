extends Resource
class_name InventorySaveData

@export var inventory: Dictionary
@export var crafted_items: Array[String]

func saveInventory(p_inventory: Array[ResItem]):
	for item in p_inventory:
		if item is ResStackItem:
			inventory[item.resource_path] = item.stack
		elif item is ResWeapon or item is ResCraftingTool:
			inventory[item.resource_path] = item.durability
		elif item is ResCharm:
			inventory[item.resource_path] = InventoryGlobals.getItemCount(item, false)

func loadInventory():
	var out_inventory = []
	
	for item_path in inventory.keys():
		if !FileAccess.file_exists(item_path): 
			continue
		var item:ResItem = load(item_path)
		var append_count = 1
		
		if item.isRepairable():
			print(item, ' is repairable!')
		
		if item is ResStackItem:
			item.stack = inventory[item_path]
			item.updateItem()
		elif item is ResCharm and inventory[item_path] is int:
			append_count = inventory[item_path]
		elif item.isRepairable():
			item.durability = min(inventory[item_path],item.max_durability)
		
		#elif item is ResCharm:
			#item.parent_item = inventory[item_path]
			#item.updateItem()
		for i in range(append_count): out_inventory.append(item)
	
	return out_inventory
