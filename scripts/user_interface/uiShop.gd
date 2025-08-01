extends Control

@onready var wares = $Wares/MarginContainer/Scroll/VBoxContainer
@onready var toggle_button = $ToggleMode
@onready var sell_barter_button = $Barter
@onready var currency = $Currency
var wares_array

var mode = 1
var buy_modifier = 1.0
var sell_modifier = 0.5
var open_description: String

func _ready():
	loadWares()

func loadWares(array=wares_array, focus_item:ResItem=null):
	sell_barter_button.disabled = !hasBarterItems()
	
	var modifier
	if mode == 1:
		modifier = buy_modifier
	else:
		modifier = sell_modifier
	array.sort_custom(func(a,b): return a.name < b.name)
	array.sort_custom(func(a,b): return InventoryGlobals.getItemType(a) < InventoryGlobals.getItemType(b))
	array.sort_custom(func(a,b): return a.value * modifier < b.value * modifier)
	clearButtons()
	
	toggle_button.disabled = false
	if mode == 1:
		toggle_button.text = 'Barter'
	elif mode == 0:
		toggle_button.text = 'Shop'
	
	for item in array:
		var button = OverworldGlobals.createItemButton(item, 0.0, mode!=1)
		var label = Label.new()
		if item.value * modifier <= 0:
			label.text = 'Free'
			label.add_theme_font_size_override('font_size', 6)
		else:
			label.text = str(floor(item.value * modifier))
		label.theme = preload("res://design/OutlinedLabel.tres")
		label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		label.set_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		button.add_child(label)
		
		if mode == 0 and item is ResStackItem:
			var count_label = Label.new()
			count_label.text = str(item.stack)
			count_label.theme = preload("res://design/OutlinedLabel.tres")
			button.add_child(count_label)
		
		if item is ResStackItem and mode == 1:
			item = ResGhostStackItem.new(item)
			item.stack = 999
		
		if (item is ResStackItem and InventoryGlobals.calculateValidAdd(item) == 0) and mode == 1:
			button.disabled = true
			label.text = ''
		
		if item.mandatory and mode == 0:
			button.disabled = true
			label.text = ''
		
		if mode == 1 and item is ResWeapon:
			button.disabled = !InventoryGlobals.canAdd(item,1,false)
			if !InventoryGlobals.canAdd(item,1,false): label.hide()
		
		if PlayerGlobals.currency >= item.value * buy_modifier and mode == 1:
			label.add_theme_color_override('font_color', Color.GREEN)
		elif mode == 1:
			label.add_theme_color_override('font_color', Color.RED)
		
		if sell_modifier > 0.5 and mode == 0:
			label.add_theme_color_override('font_color', Color.GREEN)
		elif sell_modifier < 0.5 and mode == 0:
			label.add_theme_color_override('font_color', Color.ORANGE)
		
		if item.value * buy_modifier == 0:
			label.add_theme_color_override('font_color', Color.WHITE)
		
		button.pressed.connect(
			func():
				setButtonFunction(item)
		)
		#button.mouse_exited.connect(func(): resetDescription())
		#button.focus_exited.connect(func(): resetDescription())
		wares.add_child(button)
		
		if focus_item is ResGhostStackItem and item.name == focus_item.name:
			button.grab_focus()
		elif item == focus_item:
			button.grab_focus()
		
	if focus_item == null: 
		OverworldGlobals.setMenuFocus(wares)

func clearButtons():
	for child in wares.get_children():
		wares.remove_child(child)
		child.queue_free()

func loadSlider(item)-> int:
	if !item is ResStackItem:
		return 1
	
	var a_slider = preload("res://scenes/user_interface/AmountSlider.tscn").instantiate()
	
	if mode == 1:
		if item.value * buy_modifier != 0 and floor(PlayerGlobals.currency / (item.value * buy_modifier)) <= item.reference_item.max_stack:
			a_slider.max_v = floor(PlayerGlobals.currency / floor(item.value * buy_modifier))
		else:
			a_slider.max_v = InventoryGlobals.calculateValidAdd(item)
	elif mode == 0:
		a_slider.max_v = item.stack
	
	add_child(a_slider)
	a_slider.global_position = OverworldGlobals.player.player_camera.global_position
	await a_slider.amount_enter
	var amount = a_slider.slider.value
	a_slider.queue_free()
	
	return floor(amount)

func setButtonFunction(selected_item):
	match mode:
		1: # BUY
			if PlayerGlobals.currency < selected_item.value * buy_modifier:
				OverworldGlobals.showPrompt('Not enough money for [color=yellow]%s[/color].' % selected_item.name)
				return
			
			if selected_item is ResGhostStackItem:
				OverworldGlobals.setMenuFocusMode(wares, false)
				OverworldGlobals.setMenuFocusMode(toggle_button, false)
				var amount = await loadSlider(selected_item)
				OverworldGlobals.setMenuFocusMode(wares, true)
				OverworldGlobals.setMenuFocusMode(toggle_button, true)
				InventoryGlobals.takeFromGhostStack(selected_item, amount)
				PlayerGlobals.currency -= (floor(selected_item.value * buy_modifier) * amount)
				showChange(-floor(selected_item.value * buy_modifier) * amount)
				if amount > 0:
					OverworldGlobals.playSound("res://audio/sounds/721774__maodin204__cash-register.ogg")
			else:
				InventoryGlobals.addItemResource(selected_item)
				PlayerGlobals.currency -= floor(selected_item.value * buy_modifier)
				showChange(-floor(selected_item.value * buy_modifier))
				OverworldGlobals.playSound("res://audio/sounds/721774__maodin204__cash-register.ogg")
			loadWares(wares_array, selected_item)
		0: # SELL
			if selected_item.mandatory:
				OverworldGlobals.showPrompt('[color=yellow]%s[/color] is mandatory.' % selected_item.name)
				return
			
			OverworldGlobals.setMenuFocusMode(wares, false)
			OverworldGlobals.setMenuFocusMode(toggle_button, false)
			var amount = await loadSlider(selected_item)
			OverworldGlobals.setMenuFocusMode(wares, true)
			OverworldGlobals.setMenuFocusMode(toggle_button, true)
			InventoryGlobals.removeItemResource(selected_item, amount, false)
			PlayerGlobals.currency += (floor(selected_item.value * sell_modifier) * amount)
			showChange(floor(selected_item.value * sell_modifier) * amount)
			loadWares(InventoryGlobals.inventory, selected_item)
			if amount > 0:
				OverworldGlobals.playSound("res://audio/sounds/488399__wobesound__sellingbig.ogg")
			if !InventoryGlobals.hasItem(selected_item):
				OverworldGlobals.setMenuFocus(wares)

func _on_toggle_mode_pressed():
	match mode:
		0:
			mode = 1
			loadWares(wares_array)
		1:
			mode = 0
			loadWares(InventoryGlobals.inventory)

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and !has_node('AmountSlider'):
		toggle_button.pressed.emit()

func _on_barter_pressed():
	var barter_items = []
	var sold = false
	var amount_sold
	for item in InventoryGlobals.inventory:
		if item is ResStackItem and item.barter_item: 
			barter_items.append(item)
	
	for item in barter_items:
		var amount = item.stack
		InventoryGlobals.removeItemResource(item, amount, false)
		amount_sold = (floor(item.value) * amount)
		PlayerGlobals.currency += (floor(item.value) * amount)
		if mode == 0: 
			loadWares(InventoryGlobals.inventory)
		else:
			loadWares(wares_array)
		sold = true
	if sold:
		OverworldGlobals.playSound("res://audio/sounds/488399__wobesound__sellingbig.ogg")
		showChange(amount_sold)

func hasBarterItems():
	for item in InventoryGlobals.inventory:
		if item is ResStackItem and item.barter_item: return true

func showChange(amount: int):
	if amount == 0:
		return
	
	var sold_label: Label = Label.new()
	sold_label.text = str(amount)
	sold_label.theme = preload("res://design/OutlinedLabel.tres")
	if amount >= 0:
		sold_label.modulate = Color.GREEN_YELLOW
	else:
		sold_label.modulate = Color.ORANGE_RED
	currency.add_child(sold_label)
	#sold_label.global_position = Vector2.ZERO
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sold_label, 'global_position', sold_label.global_position+Vector2(0, -8), 1.5)
	tween.tween_property(sold_label, 'modulate', Color.TRANSPARENT, 1.25)
	#var opacity_tween = create_tween().tween_property(sold_label, 'modulate', Color.TRANSPARENT, 1.0)
