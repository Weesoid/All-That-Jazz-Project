extends Control
class_name MiniInventory

@export var hide_empty_categories:bool=false
@export var show_tail:bool=true
@onready var categories = $PanelContainer/MarginContainer/VBoxContainer/Categories
@onready var resource_category = $PanelContainer/MarginContainer/VBoxContainer/Categories/Resources
@onready var camp_category = $PanelContainer/MarginContainer/VBoxContainer/Categories/CampItems
@onready var combat_category = $PanelContainer/MarginContainer/VBoxContainer/Categories/CombatItems
@onready var charm_category = $PanelContainer/MarginContainer/VBoxContainer/Categories/Charms
@onready var mini_inv = $PanelContainer/MarginContainer/VBoxContainer
@onready var items = $PanelContainer/MarginContainer/VBoxContainer/Resources/Resources
@onready var camp_items = $PanelContainer/MarginContainer/VBoxContainer/CampItems/CampItems
@onready var combat_items = $PanelContainer/MarginContainer/VBoxContainer/CombatItems/CombatItems
@onready var charms = $PanelContainer/MarginContainer/VBoxContainer/Charms/Charms
@onready var exit_button = $PanelContainer/MarginContainer/VBoxContainer/Resources/Resources/ExitButton
@onready var tail = $Tail

var item_button_map:Dictionary = {}

func _ready():
	if !show_tail:
		tail.hide()
	var orignal_pos = position
	modulate = Color.TRANSPARENT
	position += Vector2(0,16)
	create_tween().tween_property(self, 'position', orignal_pos, 0.25)
	create_tween().tween_property(self, 'modulate', Color.WHITE, 0.25)
	resource_category.pressed.connect(func(): changeCategories('Resources'))
	camp_category.pressed.connect(func(): changeCategories('CampItems'))
	combat_category.pressed.connect(func(): changeCategories('CombatItems'))
	charm_category.pressed.connect(func(): changeCategories('Charms'))
	for category in categories.get_children():
		category.focus_exited.connect(checkInFocus)

func showItems(filter:Callable=func(_item):pass):
	var inventory = InventoryGlobals.inventory.filter(filter)
	inventory.sort_custom(func(a,b): return a.name < b.name)
	for item in inventory:
		addButton(item)
	
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

func isCategoryEmpty(category)-> bool:
	return category.get_child_count() == 0

func addButton(item:ResItem):
	var button = OverworldGlobals.createItemButton(item)
	if item is ResCampItem:
		camp_items.add_child(button)
	elif item is ResWeapon:
		combat_items.add_child(button)
	elif item is ResCharm:
		charms.add_child(button)
	else:
		items.add_child(button)
	
	button.pressed.connect(
		func():
			OverworldGlobals.playSound("res://audio/sounds/421461__jaszunio15__click_46.ogg")
			queue_free()
			)
	button.focus_exited.connect(checkInFocus)
	item_button_map[item] = button

func _on_custom_button_pressed():
	queue_free()

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

func checkInFocus():
	await get_tree().process_frame
	if !hasFocus(): #and modulate == Color.WHITE:
		queue_free()

func _on_tree_exiting():
	pass
#	if get_parent() != null and !is_queued_for_deletion():
#		get_parent().grab_focus()
