extends Control
class_name MiniInventory

@export var hide_empty_categories:bool=false
@export var show_tail:bool=true

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
@onready var exit_button = $MarginContainer/VBoxContainer/Resources/Resources/ExitButton
@onready var tail = $Tail
@onready var drop_area = $ItemDropDetector

var item_button_map:Dictionary = {}

#func _init(p_hide_empty_categories, p_show_tail):
#	hide_empty_categories = p_hide_empty_categories
#	show_tail = p_show_tail

func _ready():
	if !show_tail:
		tail.hide()
	#var orignal_pos = position
	#modulate = Color.TRANSPARENT
	#position += Vector2(0,16)
	#create_tween().tween_property(self, 'position', orignal_pos, 0.25)
	#create_tween().tween_property(self, 'modulate', Color.WHITE, 0.25)
	resource_category.pressed.connect(func(): changeCategories('Resources'))
	camp_category.pressed.connect(func(): changeCategories('CampItems'))
	ammo_category.pressed.connect(func(): changeCategories('AmmoItems'))
	combat_category.pressed.connect(func(): changeCategories('CombatItems'))
	charm_category.pressed.connect(func(): changeCategories('Charms'))
	for category in categories.get_children():
		category.focus_exited.connect(checkInFocus)
	drop_area.item_dropped.connect(addButton)

func showItems(filter:Callable=func(_item):pass):
	var inventory = InventoryGlobals.inventory.filter(filter)
	inventory.sort_custom(func(a,b): return a.name < b.name)
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

func removeItem(item: ResItem):
	if !item_button_map.has(item):
		return
	
	item_button_map[item].queue_free()
	item_button_map.erase(item)

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
	return category.get_children().filter(func(button): return button != exit_button).size() == 0

func addButton(item):
	var button = OverworldGlobals.createItemButton(item)
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
	
	button.item_dragging.connect(removeItem)
#	if function != null:
#		button.pressed.connect(function)
	button.focus_exited.connect(checkInFocus)
	item_button_map[item] = button



func _on_custom_button_pressed():
	pass
	#queue_free()

func changeCategories(change_to: String):
	for child in mini_inv.get_children():
		if child.name != change_to and child.name != 'Categories':
			child.hide()
		elif child.name == change_to:
			child.show()
			exit_button.reparent(child.get_child(0))
			child.get_child(0).move_child(exit_button,0)

func hasFocus()->bool:
	if is_queued_for_deletion():
		return true
	
	if exit_button.has_focus():
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
		if child == exit_button: continue
		child.queue_free()

func checkInFocus():
	#await get_tree().process_frame
	pass
	#if !hasFocus(): #and modulate == Color.WHITE:
	#	queue_free()

func _on_tree_exiting():
	pass
#	if get_parent() != null and !is_queued_for_deletion():
#		get_parent().grab_focus()
