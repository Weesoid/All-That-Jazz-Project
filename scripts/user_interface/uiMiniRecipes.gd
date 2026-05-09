extends MiniInventory
class_name MiniRecipes


func createButton(item):
	var button: RecipeButton = load("res://scenes/user_interface/CustomRecipeButton.tscn").instantiate()
	button.item = InventoryGlobals.loadItemResource(item)
	#button.setItem(InventoryGlobals.loadItemResource(item))
	return button

func getItemCatalog(filter):
	var catalog = InventoryGlobals.crafted_items.filter(filter)
	return catalog
