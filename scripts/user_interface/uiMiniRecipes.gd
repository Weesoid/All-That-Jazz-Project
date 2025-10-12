extends MiniInventory
class_name MiniRecipes

const RECIPE_BUTTON = preload("res://scenes/user_interface/CustomRecipeButton.tscn")

func showItems(filter:Callable=func(_item):pass):
	var inventory = InventoryGlobals.crafted_items
	for item in inventory:
		addButton(item)
	
	if !hide_empty_categories:
		resource_category.setDisabled(isCategoryEmpty(items))
		camp_category.setDisabled(isCategoryEmpty(camp_items))
		ammo_category.setDisabled(isCategoryEmpty(ammo_items))
		combat_category.setDisabled(isCategoryEmpty(combat_items))
		charm_category.setDisabled(isCategoryEmpty(charms))
	else:
		resource_category.visible = !isCategoryEmpty(items)
		camp_category.visible = !isCategoryEmpty(camp_items)
		ammo_category.visible = !isCategoryEmpty(ammo_items)
		combat_category.visible = !isCategoryEmpty(combat_items)
		charm_category.visible = !isCategoryEmpty(charms)
	
	focusFirstFilled()

func addButton(item):
	var button = RECIPE_BUTTON.instantiate()
	button.item_filename = item
	var item_resource = load("res://resources/items/%s.tres" % item)
	
	if item_resource is ResCampItem:
		camp_items.add_child(button)
	elif item_resource is ResProjectileAmmo:
		ammo_items.add_child(button)
	elif item_resource is ResWeapon:
		combat_items.add_child(button)
	elif item_resource is ResCharm:
		charms.add_child(button)
	else:
		items.add_child(button)
	
	button.focus_exited.connect(checkInFocus)
	item_button_map[item_resource] = button
