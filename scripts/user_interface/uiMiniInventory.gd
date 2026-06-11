extends Control
class_name MiniInventory

@export var hide_empty_categories:bool=false
@export var remove_dragged_items:bool=true
@export var yellow_border:bool=true
@export var description_offset=Vector2(0,0)
@export var remove_drop_detector:bool=false
@export var update_inventory:bool=true
@export var tooltip_direction:CustomTooltip.AnchorPreset = CustomTooltip.AnchorPreset.BOTTOM
@export var show_corner_closer:bool=false

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
@onready var closer = $MenuCloser
#@onready var drop_detector = $ItemDropDetector

var item_button_map:Dictionary = {}
var category_containers:Dictionary = {}
var current_category

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
	category_containers[resource_category] = items
	category_containers[camp_category] = camp_items
	category_containers[ammo_category] = ammo_items
	category_containers[combat_category] = combat_items
	category_containers[charm_category] = charms

#	if remove_dragged_items and !remove_drop_detector:
#		drop_detector.item_not_dropped.connect(addButton)
#	if remove_drop_detector:
#		drop_detector.queue_free()
	if update_inventory:
		InventoryGlobals.added_item_to_inventory.connect(addButton)
		InventoryGlobals.removed_item_from_inventory.connect(removeItem)
	
	
	inheritorReady()
	#focusFirstFilled()
	closer.visible = show_corner_closer 

func inheritorReady():
	pass

func showItems(filter:Callable=func(_item):return true):
	var inventory = getItemCatalog(filter)
	
	for item in inventory:
		addButton(item)
	
	updateCategories()
	focusFirstFilled()

func updateCategories():
	if !visible:
		return
	
	await get_tree().process_frame
	for category in category_containers:
		if hide_empty_categories:
			category.visible = !isCategoryEmpty(category_containers[category])
		else:
			category.setDisabled(isCategoryEmpty(category_containers[category]))
	
	if current_category != null and current_category.get_child_count() == 0:
		focusFirstFilled()



#func currentCategory():
#	for item_container in category_containers.values():
#		if item_container.find_children('*', 'ItemButton').size() > 0 and item_container.visible:
#			return item_container
#	for item_container in mini_inv.get_children():
#		if item_container == categories: 
#			continue
#		elif item_container.visible and :
#			print(item_container, ' passed!')
#			return item_container
#
#	return null

func focusFirstFilled():
	for category in categories.get_children():
		var node_path='MarginContainer/VBoxContainer/%s/%s' % [category.name,category.name]
		if !has_node(node_path):
			continue

		var category_container = get_node(node_path)
		if !isCategoryEmpty(category_container):
			changeCategories(category.name)
			category_container.get_child(0).grab_focus()
			return

func focusCategory(item:ResItem):
	getCategory(item).get_child(0).grab_focus()

func getCategory(item:ResItem):
	if item is ResCharm:
		return charms
	elif item is ResWeapon:
		return combat_items
	elif item is ResProjectileAmmo:
		return ammo_items
	elif item is ResCampItem:
		return camp_items
	else:
		return items

func isCategoryEmpty(category)-> bool:
	#print(category, ': ', category.get_children().size())
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
	if button.has_node('CustomTooltip'):
		button.get_node('CustomTooltip').tooltip_position = tooltip_direction
	
	
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

func changeCategories(change_to: String):
	for child in mini_inv.get_children():
		if child.name != change_to and child.name != 'Categories':
			child.hide()
		elif child.name == change_to:
			current_category = child.get_child(0)
			child.show()
		

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
