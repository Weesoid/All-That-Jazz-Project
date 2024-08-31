extends TextureRect

@onready var player = OverworldGlobals.getPlayer()
@onready var select_name = $Name

var current_index = -1
var equipped_power: ResPower

func _input(event):
	if Input.is_action_just_pressed("ui_select_arrow"):
		if PlayerGlobals.EQUIPPED_ARROW != null:
			updateIcon(PlayerGlobals.EQUIPPED_ARROW.ICON, PlayerGlobals.EQUIPPED_ARROW.NAME)
	if Input.is_action_just_pressed("ui_select_gambit"):
		if equipped_power != null:
			updateIcon(equipped_power.ICON, equipped_power.NAME)
	
	if Input.is_action_pressed("ui_select_arrow"):
		visible = true
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				current_index -= 1
				updateArrowSelect()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				current_index += 1
				updateArrowSelect()
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_B and event.pressed:
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
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_B and event.pressed:
				current_index += 1
				updatePowerSelect()
	
	if Input.is_action_just_released('ui_select_arrow') or Input.is_action_just_released('ui_select_gambit'):
		texture = null
		select_name.text = ''
		visible = false
	
func updatePowerSelect():
	if InventoryGlobals.KNOWN_POWERS.is_empty():
		return
	
	if current_index > InventoryGlobals.KNOWN_POWERS.size() - 1:
		current_index = 0
	elif current_index < 0:
		current_index = InventoryGlobals.KNOWN_POWERS.size() - 1
	
	updateIcon(
		InventoryGlobals.KNOWN_POWERS[current_index].ICON, 
		InventoryGlobals.KNOWN_POWERS[current_index].NAME
		)
	InventoryGlobals.KNOWN_POWERS[current_index].setPower()
	equipped_power = InventoryGlobals.KNOWN_POWERS[current_index]

func updateArrowSelect():
	var arrows = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	if arrows.size() <= 1:
		return
	
	if current_index > InventoryGlobals.KNOWN_POWERS.size() - 1:
		current_index = 0
	elif current_index < 0:
		current_index = InventoryGlobals.KNOWN_POWERS.size() - 1
	
	updateIcon(arrows[current_index].ICON, arrows[current_index].NAME)
	arrows[current_index].equip()

func updateIcon(icon, display_name):
	texture = icon
	select_name.text = display_name
