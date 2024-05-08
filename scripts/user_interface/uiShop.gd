extends Control

@onready var wares = $Wares/MarginContainer/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var stats = $StatsPanel/Label
@onready var toggle_button = $ToggleMode
@onready var currency = $Currency

var wares_array

var mode = 1
var buy_modifier = 1.0
var sell_modifier = 0.5
var open_description: String

func _ready():
	loadWares()
	resetDescription()

func _process(_delta):
	currency.text = str(PlayerGlobals.CURRENCY)

func loadWares(array=wares_array):
	var modifier
	if mode == 1:
		modifier = buy_modifier
	else:
		modifier = sell_modifier
	array.sort_custom(func(a,b): return a.NAME > b.NAME)
	array.sort_custom(func(a,b): return a.VALUE * modifier < b.VALUE * modifier)
	clearButtons()
	
	toggle_button.disabled = false
	if mode == 1:
		toggle_button.text = 'Barter'
	elif mode == 0:
		toggle_button.text = 'Shop'
	
	for item in array:
		var button = OverworldGlobals.createItemButton(item)
		
		var label = Label.new()
		if item.VALUE * modifier <= 0:
			label.text = 'Free'
			label.add_theme_font_size_override('font_size', 6)
		else:
			label.text = str(int(item.VALUE * modifier))
		label.theme = preload("res://design/OutlinedLabel.tres")
		label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		label.set_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		button.add_child(label)
		
		if mode == 0 and item is ResStackItem:
			var count_label = Label.new()
			count_label.text = str(item.STACK)
			count_label.theme = preload("res://design/OutlinedLabel.tres")
			button.add_child(count_label)
		
		if item is ResStackItem and mode == 1:
			item = ResGhostStackItem.new(item)
			item.STACK = 999
		
		if (item is ResUtilityCharm and PlayerGlobals.EQUIPPED_CHARM == item) or (item is ResEquippable and !InventoryGlobals.canAdd(item,1,false)) and mode == 1:
			button.disabled = true
			label.text = ''
		
		if (item is ResStackItem and InventoryGlobals.calculateValidAdd(item) == 0) and mode == 1:
			button.disabled = true
			label.text = ''
		
#		if item.MANDATORY and mode == 0:
#			button.disabled = true
#			label.text = ''
		
		if PlayerGlobals.CURRENCY >= item.VALUE * buy_modifier and mode == 1:
			label.add_theme_color_override('font_color', Color.GREEN)
		elif mode == 1:
			label.add_theme_color_override('font_color', Color.RED)
		
		if sell_modifier > 0.5 and mode == 0:
			label.add_theme_color_override('font_color', Color.GREEN)
		elif sell_modifier < 0.5 and mode == 0:
			label.add_theme_color_override('font_color', Color.ORANGE)
		
		if item.VALUE * buy_modifier == 0:
			label.add_theme_color_override('font_color', Color.WHITE)
		
		button.pressed.connect(
			func():
				setButtonFunction(item, button)
		)
		button.mouse_entered.connect(
			func updateDescription():
				description.text = item.getInformation()
				if item is ResEquippable:
					stats.text = item.getStringStats()
		)
		button.mouse_exited.connect(func(): resetDescription())
		wares.add_child(button)

func clearButtons():
	for child in wares.get_children():
		child.queue_free()

func resetDescription():
	description.text = open_description
	stats.text = ''
	if buy_modifier < 1.0:
		stats.text += '[color=green]Discounted prices[/color]\n'
	elif buy_modifier > 1.0:
		stats.text += '[color=orange]Increased prices[/color]\n'
	
	if sell_modifier > 0.5:
		stats.text += '[color=green]Increased sell value[/color]\n'
	elif sell_modifier < 0.5:
		stats.text += '[color=orange]Decreased sell value[/color]\n'

func loadSlider(item)-> int:
	if !item is ResStackItem:
		return 1
	
	var a_slider = preload("res://scenes/user_interface/AmountSlider.tscn").instantiate()
	
	if mode == 1:
		if item.VALUE * buy_modifier != 0 and int(PlayerGlobals.CURRENCY / (item.VALUE * buy_modifier)) <= item.REFERENCE_ITEM.MAX_STACK:
			a_slider.max_v = int(PlayerGlobals.CURRENCY / (item.VALUE * buy_modifier))
		else:
			a_slider.max_v = InventoryGlobals.calculateValidAdd(item)
	elif mode == 0:
		a_slider.max_v = item.STACK
	
	add_child(a_slider)
	a_slider.position = Vector2(0,0)
	await a_slider.amount_enter
	var amount = a_slider.slider.value
	a_slider.queue_free()
	
	return int(amount)

func setButtonFunction(selected_item, button: Button):
	match mode:
		1:
			if PlayerGlobals.CURRENCY < selected_item.VALUE * buy_modifier:
				OverworldGlobals.showPlayerPrompt('Not enough money for [color=yellow]%s[/color].' % selected_item.NAME)
				return
			
			if selected_item is ResGhostStackItem:
				var amount = await loadSlider(selected_item)
				InventoryGlobals.takeFromGhostStack(selected_item, amount)
				PlayerGlobals.CURRENCY -= int((selected_item.VALUE * buy_modifier) * amount)
			else:
				InventoryGlobals.addItemResource(selected_item)
				PlayerGlobals.CURRENCY -= int(selected_item.VALUE * buy_modifier)
			loadWares(wares_array)
		0:
			if selected_item.MANDATORY:
				OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] is mandatory.' % selected_item.NAME)
				return
			
			var amount = await loadSlider(selected_item)
			InventoryGlobals.removeItemResource(selected_item, amount, false)
			PlayerGlobals.CURRENCY += int((selected_item.VALUE * sell_modifier) * amount)
			loadWares(InventoryGlobals.INVENTORY)

func _on_toggle_mode_pressed():
	match mode:
		1:
			mode = 0
			loadWares(InventoryGlobals.INVENTORY)
		0: 
			mode = 1
			loadWares(wares_array)
