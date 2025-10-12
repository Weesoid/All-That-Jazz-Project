extends MiniInventory
class_name MiniRepair

const REPAIR_BUTTON = preload("res://scenes/user_interface/CustomRepairButton.tscn")

func showItems(filter:Callable=func(_item):return true):
	var team = PlayerGlobals.team.filter(filter)
	print(team)
	for combatant in team:
		addButton(combatant)
	
	if !hide_empty_categories:
		combat_category.setDisabled(isCategoryEmpty(combat_items))
	else:
		combat_category.visible = !isCategoryEmpty(combat_items)
	
	print(isCategoryEmpty(combat_items))
	changeCategories('CombatItems')

func addButton(item): ## Item is actually a combatant or weapon
	print(item)
	if !item.hasEquippedWeapon():
		return
	
	var item_resource
	var button = REPAIR_BUTTON.instantiate()
	if item is ResPlayerCombatant:
		button.combatant = item
		button.weapon = item.equipped_weapon
		item_resource = load("res://resources/items/%s.tres" % item.equipped_weapon.getFilename())
	elif item is ResWeapon:
		button.weapon = item
		item_resource = load("res://resources/items/%s.tres" % item.getFilename())
	
	combat_items.add_child(button)
	button.focus_exited.connect(checkInFocus)
	item_button_map[item_resource] = button
