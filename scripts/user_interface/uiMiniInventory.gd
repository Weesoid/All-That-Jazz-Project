extends Control
class_name MiniInventory

@export var hide_empty_categories:bool=false
@export var remove_dragged_items:bool=true
@export var yellow_border:bool=true
@export var description_offset=Vector2(0,0)
@export var remove_drop_detector:bool=false
@export var update_inventory:bool=true

@onready var categories = $MarginContainer/VBoxContainer/Categories
@onready var resource_category = $MarginContainer/VBoxContainer/Categories/Resources
@onready var camp_category = $MarginContainer/VBoxContainer/Categories/CampItems
@onready var ammo_category = $MarginContainer/VBoxContainer/Categories/AmmoItems
@onready var combat_category = $MarginContainer/VBoxContainer/Categories/CombatItems
@onready var charm_category = $MarginContainer/VBoxContainer/Categories/Charms
@onready var mini_inv = $MarginContainer/VBoxContainer
@onready var items = $MarginContainer/VBoxContainer/Resources/Resources
@onready var camp_items = $MarginContainer/VBoxContainer/CampItems/CampItems
@onready var ammo_items = $MarginContainer/VBoxContainer/AmmoItems/AmmoItems
@onready var combat_items = $MarginContainer/VBoxContainer/CombatItems/CombatItems
@onready var charms = $MarginContainer/VBoxContainer/Charms/Charms
#@onready var drop_detector = $ItemDropDetector

var item_button_map:Dictionary = {}

signal item_button_added(button)
signal item_button_removed(item)

func _ready():
	if !yellow_border:
		theme = null
	
	resource_category.pressed.connect(func(): changeCategories('Resources'))
	camp_category.pressed.connect(func(): changeCategories('CampItems'))
	ammo_category.pressed.connect(func(): changeCategories('AmmoItems'))
	combat_category.pressed.connect(func(): changeCategories('CombatItems'))
	charm_category.pressed.connect(func(): changeCategories('Charms'))

#	if remove_dragged_items and !remove_drop_detector:
#		drop_detector.item_not_dropped.connect(addButton)
#	if remove_drop_detector:
#		drop_detector.queue_free()
	if update_inventory:
		InventoryGlobals.added_item_to_inventory.connect(addButton)
		InventoryGlobals.removed_item_from_inventory.connect(removeItem)
	
	inheritorReady()
	focusFirstFilled()
	
func inheritorReady():
	pass

func showItems(filter:Callable=func(_item):return true):
	var inventory = getItemCatalog(filter)
	
	for item in inventory:
		addButton(item)
	
	updateCategories()
	focusFirstFilled()

func updateCategories():
	await get_tree().process_frame
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




func focusFirstFilled():
	for category in categories.get_children():
		var node_path='MarginContainer/VBoxContainer/%s/%s' % [category.name,category.name]
		if !has_node(node_path):
			continue
		
		var category_container = get_node(node_path)
		if !isCategoryEmpty(category_container):
			changeCategories(category.name)
			return

func isCategoryEmpty(category)-> bool:
	return category.get_children().size() == 0

func addButton(item,_count=null):
	if item_button_map.has(item) and item is ResStackItem:
		return
	var button = createButton(item)
	if item is String and FileAccess.file_exists("res://resources/items/%s.tres" % item):
		item = load("res://resources/items/%s.tres" % item)
	
	if item is ResCampItem:
		camp_items.add_child(button)
	elif item is ResProjectileAmmo:
		ammo_items.add_child(button)
	elif item is ResWeapon:
		combat_items.add_child(button)
	elif item is ResCharm:
		charms.add_child(button)
	else:
		items.add_child(button)
	
	if remove_dragged_items and button is CustomDragDropButton:
		button.item_dragging.connect(removeItem)
	updateCategories()
	addButtonToMap(item, button)
	item_button_added.emit(button)


func removeItem(item: ResItem):
	if !item_button_map.has(item):
		return
	
	item_button_map[item][0].queue_free()
	item_button_map[item].remove_at(0)
	if item_button_map[item].is_empty():
		item_button_map.erase(item)
	updateCategories()
	item_button_removed.emit(item)

func addButtonToMap(item,button):
	if item_button_map.has(item):
		item_button_map[item].append(button)
	else:
		item_button_map[item] = [button]

func getButtons():
	var out = []
	for buttons in item_button_map.values():
		out.append_array(buttons)
	return out

func createButton(item):
	return UIGlobals.createItemButton(item)

func getItemCatalog(filter):
	var catalog = InventoryGlobals.inventory.filter(filter)
	catalog.sort_custom(func(a,b): return a.name < b.name)
	return catalog

func _on_custom_button_pressed():
	pass

func changeCategories(change_to: String):
	for child in mini_inv.get_children():
		if child.name != change_to and child.name != 'Categories':
			child.hide()
		elif child.name == change_to:
			child.show()

func hasFocus()->bool:
	if is_queued_for_deletion():
		return true
	
	for child in categories.get_children():
		if child.has_focus(): return true
	for item in item_button_map.keys():
		if item_button_map[item].has_focus(): return true
	
	return false

func reset():
	clearChildren(camp_items)
	clearChildren(ammo_items)
	clearChildren(combat_items)
	clearChildren(charms)
	clearChildren(items)
	item_button_map.clear()

func clearChildren(menu):
	for child in menu.get_children(): 
		child.queue_free()
