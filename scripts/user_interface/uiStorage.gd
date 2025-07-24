extends Control

@onready var storage = $Storage/Scroll/VBoxContainer
@onready var inventory = $Inventory/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var search = $LineEdit

var selected_item

func _ready():
	print('Depracated!')

func loadStorage():
	clearButtons(storage)
	clearButtons(inventory)
	for item in InventoryGlobals.STORAGE:
		createButton(item, storage)
	for item in InventoryGlobals.inventory:
		if item.WEIGHT > 0.0:
			createButton(item, inventory)

func createButton(item, location):
	var button = OverworldGlobals.createCustomButton()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.x = 170
	button.text = item._to_string()
	if item.MANDATORY:
		button.disabled = true
		location.add_child(button)
		return
	button.pressed.connect(
		func transferItem():
			if InventoryGlobals.inventory.has(item):
				InventoryGlobals.transferItem(item, await loadSlider(item), InventoryGlobals.inventory, InventoryGlobals.STORAGE)
				loadStorage()
			elif InventoryGlobals.STORAGE.has(item):
				InventoryGlobals.transferItem(item, await loadSlider(item), InventoryGlobals.STORAGE, InventoryGlobals.inventory)
				loadStorage()
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = ''
			description.text = item.getInformation()
	)
	location.add_child(button)

func loadSlider(item)-> int:
	if !item is ResStackItem:
		return 1
	
	var a_slider = preload("res://scenes/user_interface/AmountSlider.tscn").instantiate()
	a_slider.max_v = item.STACK
	add_child(a_slider)
	await a_slider.amount_enter
	var amount = a_slider.slider.value
	a_slider.queue_free()
	return amount

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
