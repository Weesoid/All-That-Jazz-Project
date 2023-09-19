extends Control

@onready var storage = $Storage/Scroll/VBoxContainer
@onready var inventory = $Inventory/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var stats = $StatsPanel/Label
@onready var search = $LineEdit

var selected_item

func _ready():
	loadStorage()

func loadStorage():
	clearButtons(storage)
	clearButtons(inventory)
	for item in PlayerGlobals.STORAGE:
		createButton(item, storage)
	for item in PlayerGlobals.INVENTORY:
		createButton(item, inventory)

func createButton(item, location):
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.x = 170
	button.text = item.NAME
	button.pressed.connect(
		func transferItem():
			if PlayerGlobals.INVENTORY.has(item):
				if item is ResEquippable and item.isEquipped():
					item.unequip()
				PlayerGlobals.STORAGE.append(item)
				PlayerGlobals.INVENTORY.erase(item)
				inventory.remove_child(button)
				storage.add_child(button)
			elif PlayerGlobals.STORAGE.has(item):
				PlayerGlobals.INVENTORY.append(item)
				PlayerGlobals.STORAGE.erase(item)
				storage.remove_child(button)
				inventory.add_child(button)
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = item.DESCRIPTION
			if item is ResEquippable:
				stats.text = item.getStringStats()
	)
	location.add_child(button)

func filter(item_name):
	filterButtons(storage, item_name)
	filterButtons(inventory, item_name)

func filterButtons(container, key):
	for child in container.get_children():
		if !child.text.contains(key):
			child.queue_free()

func clearButtons(container):
	for child in container.get_children():
		child.queue_free()

func _on_line_edit_text_changed(new_text):
	if new_text.is_empty():
		loadStorage()
	else:
		filter(new_text)

func _on_button_pressed():
	search.text_submitted.emit(search.text)

func _on_reset_pressed():
	loadStorage()
