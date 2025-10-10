extends MiniInventory
class_name MiniRecipes

const RECIPE_BUTTON = preload("res://scenes/user_interface/CustomRecipeButton.tscn")

func showItems(filter:Callable=func(_item):pass):
	#print(InventoryGlobals.crafted_items)
	var inventory = InventoryGlobals.crafted_items
	#inventory.sort_custom(func(a,b): return a.name < b.name)
	print(inventory)
	for item in inventory:
		addButtonx(item)
	
	if !hide_empty_categories:
		resource_category.setDisabled(isCategoryEmpty(items))
		camp_category.setDisabled(isCategoryEmpty(camp_items))
		combat_category.setDisabled(isCategoryEmpty(combat_items))
		charm_category.setDisabled(isCategoryEmpty(charms))
	else:
		resource_category.visible = isCategoryEmpty(items)
		camp_category.visible = isCategoryEmpty(camp_items)
		combat_category.visible = isCategoryEmpty(combat_items)
		charm_category.visible = isCategoryEmpty(charms)
	
	OverworldGlobals.setMenuFocus(resource_category)

func addButtonx(item_name:String):
	var button = RECIPE_BUTTON.instantiate()
	button.item_filename = item_name
	var item = load("res://resources/items/%s.tres" % item_name)
	
	if item is ResCampItem:
		camp_items.add_child(button)
	elif item is ResWeapon:
		combat_items.add_child(button)
	elif item is ResCharm:
		charms.add_child(button)
	else:
		items.add_child(button)
	
#	button.pressed.connect(
#		func():
#			OverworldGlobals.playSound("res://audio/sounds/421461__jaszunio15__click_46.ogg")
#			queue_free()
#			)
	button.focus_exited.connect(checkInFocus)
	item_button_map[item] = button
