extends TextureRect

@onready var player = OverworldGlobals.getPlayer()
@onready var select_name = $Name

var current_index = -1

func _input(event):
	var arrows = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	if arrows.is_empty():
		return
	
	if Input.is_action_just_pressed("ui_select_arrow"):
		if PlayerGlobals.EQUIPPED_ARROW != null:
			updateIcon(PlayerGlobals.EQUIPPED_ARROW.ICON, PlayerGlobals.EQUIPPED_ARROW.NAME)
	
	if Input.is_action_pressed("ui_select_arrow"):
		visible = true
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				incrementIndex(current_index, -1, arrows.size())
				updateArrowSelect()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				incrementIndex(current_index, 1, arrows.size())
				updateArrowSelect()
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_B and event.pressed:
				incrementIndex(current_index, 1, arrows.size())
				updateArrowSelect()
			if event.button_index == JOY_BUTTON_A and event.pressed:
				incrementIndex(current_index, -1, arrows.size())
				updateArrowSelect()
	
	if Input.is_action_just_released('ui_select_arrow'):
		texture = null
		select_name.text = ''
		visible = false

func updateArrowSelect():
	var arrows = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	if arrows.size() <= 1:
		return
	
	updateIcon(arrows[current_index].ICON, arrows[current_index].NAME)
	arrows[current_index].equip()

func updateIcon(icon, display_name):
	texture = icon
	select_name.text = display_name

func incrementIndex(index:int, increment: int, limit: int):
	return (index + increment) % limit
