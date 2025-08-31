extends Container

var current_index = -1

func _input(event):
	var arrows: Array = InventoryGlobals.inventory.filter(func(item): return item is ResProjectileAmmo)
	arrows.sort_custom(func(a, b): return a.name < b.name)
	if arrows.is_empty():
		return
	
	if Input.is_action_just_pressed("ui_select_arrow") and OverworldGlobals.player.is_processing_input():
		for child in get_children():
			child.queue_free()
			await child.tree_exited
		for arrow in arrows:
			loadOtherArrows(arrow)
		current_index = arrows.find(PlayerGlobals.equipped_arrow)
		OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg")
	if Input.is_action_pressed("ui_select_arrow") and OverworldGlobals.player.is_processing_input():
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
		visible = false

func updateArrowSelect():
	var arrows = InventoryGlobals.inventory.filter(func(item): return item is ResProjectileAmmo)
	arrows.sort_custom(func(a, b): return a.name < b.name)
	if arrows.size() <= 1:
		return
	
	if current_index > arrows.size() - 1:
		current_index = 0
	elif current_index < 0:
		current_index = arrows.size() - 1
	arrows[current_index].equip()
	
	for child in get_children():
		child.queue_free()
		await child.tree_exited
	for arrow in arrows:
		loadOtherArrows(arrow)

func loadOtherArrows(arrow: ResProjectileAmmo):
	var texture = TextureRect.new()
	texture.texture = arrow.icon
	texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	
	if PlayerGlobals.equipped_arrow != arrow:
		#texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		texture.modulate = Color(Color.WHITE, 0.25)
	add_child(texture)
