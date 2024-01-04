extends TextureRect

@onready var player = OverworldGlobals.getPlayer()
@onready var select_name = $Name

var current_index = -1
var selected_arrow: ResProjectileAmmo

func _input(event):
	if Input.is_action_pressed("ui_select_arrow"):
		visible = true
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				current_index -= 1
				updateArrowSelect()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				current_index += 1
				updateArrowSelect()
			
	elif Input.is_action_pressed("ui_select_gambit") and !player.channeling_power:
		visible = true
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				current_index -= 1
				updatePowerSelect()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				current_index += 1
				updatePowerSelect()
	else:
		texture = null
		select_name.text = 'SCROLL'
		visible = false

func updatePowerSelect():
	if InventoryGlobals.KNOWN_POWERS.is_empty():
		return
	
	if current_index > InventoryGlobals.KNOWN_POWERS.size() - 1:
		current_index = 0
	elif current_index < 0:
		current_index = InventoryGlobals.KNOWN_POWERS.size() - 1
	
	texture = InventoryGlobals.KNOWN_POWERS[current_index].ICON
	select_name.text = InventoryGlobals.KNOWN_POWERS[current_index].NAME
	InventoryGlobals.KNOWN_POWERS[current_index].setPower()

func updateArrowSelect():
	var arrows = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	if arrows.size() <= 1:
		return
	
	if current_index > InventoryGlobals.KNOWN_POWERS.size() - 1:
		current_index = 0
	elif current_index < 0:
		current_index = InventoryGlobals.KNOWN_POWERS.size() - 1
	
	texture = arrows[current_index].ICON
	select_name.text = arrows[current_index].NAME
	selected_arrow = arrows[current_index]
	selected_arrow.equip()
