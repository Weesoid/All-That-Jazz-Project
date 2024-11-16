extends Node2D

@onready var player = OverworldGlobals.getPlayer()
@onready var select_name = $TextureRect/Name
@onready var equipped_texture = $TextureRect
@onready var other_arrows_container = $HBoxContainer

var current_index = -1

func _input(event):
	if !player.is_processing_input():
		return
	
	var arrows: Array = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	arrows.sort_custom(func(a, b): return a.NAME < b.NAME)
	if arrows.is_empty():
		return
	
	if Input.is_action_just_pressed("ui_select_arrow"):
		for child in other_arrows_container.get_children():
			child.queue_free()
			await child.tree_exited
		for arrow in arrows:
			loadOtherArrows(arrow)
		current_index = arrows.find(PlayerGlobals.EQUIPPED_ARROW)
		updateIcon(arrows[current_index].ICON, arrows[current_index].NAME)
		OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg")
	if Input.is_action_pressed("ui_select_arrow"):
		visible = true
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				current_index += 1
				updateArrowSelect()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				current_index -= 1
				updateArrowSelect()
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_B and event.pressed:
				current_index += 1
				updateArrowSelect()
			if event.button_index == JOY_BUTTON_A and event.pressed:
				current_index -= 1
				updateArrowSelect()
	if Input.is_action_just_released('ui_select_arrow'):
		equipped_texture.texture = null
		select_name.text = ''
		visible = false

func updateArrowSelect():
	var arrows = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	arrows.sort_custom(func(a, b): return a.NAME < b.NAME)
	if arrows.size() <= 1:
		return
	
	if current_index > arrows.size() - 1:
		current_index = 0
	elif current_index < 0:
		current_index = arrows.size() - 1
	updateIcon(arrows[current_index].ICON, arrows[current_index].NAME)
	arrows[current_index].equip()
	
	for child in other_arrows_container.get_children():
		child.queue_free()
		await child.tree_exited
	for arrow in arrows:
		loadOtherArrows(arrow)

func loadOtherArrows(arrow: ResProjectileAmmo):
	var texture = TextureRect.new()
	texture.texture = arrow.ICON
	texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	if PlayerGlobals.EQUIPPED_ARROW != arrow:
		texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture.modulate = Color(Color.WHITE, 0.25)
	other_arrows_container.add_child(texture)

func updateIcon(icon, display_name):
	equipped_texture.texture = icon
	if display_name != '':
		select_name.text = display_name.to_upper()
