extends MiniInventory
class_name MiniRecipes

@onready var repair_category = $MarginContainer/VBoxContainer/Categories/Repair
@onready var repair_items = $MarginContainer/VBoxContainer/RepairRecipes/RepairRecipes

func inheritorReady():
	InventoryGlobals.recipe_added.connect(addButton)
	repair_category.pressed.connect(func(): changeCategories('RepairRecipes'))
	loadRepairRecipes()

func createButton(item):
	var is_repair_recipe=false
	if item.split('.').size() > 1:
		item = item.split('.')[0]
		is_repair_recipe=true
	var button: RecipeButton = load("res://scenes/user_interface/CustomRecipeButton.tscn").instantiate()
	button.item = InventoryGlobals.loadItemResource(item)
	button.is_repair_recipe = is_repair_recipe
	InventoryGlobals.removed_item_from_inventory.connect(button.update.unbind(1))
	InventoryGlobals.added_item_to_inventory.connect(button.update.unbind(2))
	InventoryGlobals.stack_item_changed.connect(button.update.unbind(3))
	return button

func getItemCatalog(filter):
	var catalog = InventoryGlobals.crafted_items.filter(filter)
	return catalog

func loadRepairRecipes():
	var repair_recipes = InventoryGlobals.getRepairRecipes()
	for recipe in repair_recipes.keys():
		var button = createButton(recipe)
		if remove_dragged_items and button is CustomDragDropButton:
			button.item_dragging.connect(removeItem)
			button.description_offset = description_offset
		repair_items.add_child(button)
		addButtonToMap(recipe, button)
	updateCategories()

func updateCategories():
	await get_tree().process_frame
	if !hide_empty_categories:
		resource_category.setDisabled(isCategoryEmpty(items))
		camp_category.setDisabled(isCategoryEmpty(camp_items))
		ammo_category.setDisabled(isCategoryEmpty(ammo_items))
		combat_category.setDisabled(isCategoryEmpty(combat_items))
		charm_category.setDisabled(isCategoryEmpty(charms))
		repair_category.setDisabled(isCategoryEmpty(repair_items))
	else:
		resource_category.visible = !isCategoryEmpty(items)
		camp_category.visible = !isCategoryEmpty(camp_items)
		ammo_category.visible = !isCategoryEmpty(ammo_items)
		combat_category.visible = !isCategoryEmpty(combat_items)
		charm_category.visible = !isCategoryEmpty(charms)
		repair_category.visible = !isCategoryEmpty(repair_items)
