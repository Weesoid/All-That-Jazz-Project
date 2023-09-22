extends Control

@onready var wares = $Wares/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var stats = $StatsPanel/Label
@onready var action_button = $Action
@onready var toggle_button = $ToggleMode
@onready var currency = $Currency

var wares_array

var mode = 1
var selected_item
var buy_modifier = 1.0
var sell_modifier = 0.5

func _ready():
	loadWares()

func _process(_delta):
	currency.text = str(PlayerGlobals.CURRENCY)

func loadWares(array=wares_array):
	array.sort_custom(func(a,b): return a.NAME > b.NAME)
	clearButtons()
	var modifier
	if mode == 1:
		modifier = buy_modifier
	else:
		modifier = sell_modifier
	
	action_button.disabled = true
	toggle_button.disabled = false
	if mode == 1:
		action_button.text = 'Purchase'
		toggle_button.text = 'Barter'
	elif mode == 0:
		action_button.text = 'Sell'
		toggle_button.text = 'Shop'
	
	for item in array:
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x = 360
		if item is ResStackItem and mode == 1:
			item = ResGhostStackItem.new(item)
			item.STACK = 999
		
		button.text = "%s (%s)" % [item, int(item.VALUE * modifier)]
		
		if item is ResEquippable and !PlayerGlobals.canAdd(item,1,false,false) and mode == 1: # TO DO Add no show prompt
			button.disabled = true
		
		button.pressed.connect(
			func setSelected():
				selected_item = item
				if PlayerGlobals.CURRENCY < selected_item.VALUE * buy_modifier and mode == 1:
					action_button.disabled = true
				else:
					action_button.disabled = false
		)
		button.mouse_entered.connect(
			func updateDescription():
				description.text = ''
				stats.text = ''
				
				description.text = item.DESCRIPTION
				if item is ResEquippable:
					stats.text = item.getStringStats()
		)
		wares.add_child(button)

func clearButtons():
	for child in wares.get_children():
		child.queue_free()

func disableButtons():
	for child in wares.get_children():
		child.disabled = true
	
	toggle_button.disabled = true
	action_button.disabled = true

func loadSlider(item)-> int:
	if !item is ResStackItem:
		return 1
	
	disableButtons()
	var a_slider = preload("res://scenes/user_interface/AmountSlider.tscn").instantiate()
	
	if mode == 1:
		if item.VALUE != 0:
			a_slider.max_v = PlayerGlobals.CURRENCY / (item.VALUE * buy_modifier)
		else:
			a_slider.max_v = item.STACK
	elif mode == 0:
		a_slider.max_v = item.STACK
	
	add_child(a_slider)
	await a_slider.amount_enter
	var amount = a_slider.slider.value
	a_slider.queue_free()
	return int(amount)

func _on_action_pressed():
	match mode:
		1:
			if selected_item is ResGhostStackItem:
				var amount = await loadSlider(selected_item)
				PlayerGlobals.takeFromGhostStack(selected_item, amount, true)
				PlayerGlobals.CURRENCY -= int((selected_item.VALUE * buy_modifier) * amount)
			else:
				PlayerGlobals.addItemResource(selected_item)
			loadWares(wares_array)
		0:
			var amount = await loadSlider(selected_item)
			PlayerGlobals.removeItemResource(selected_item, amount)
			PlayerGlobals.CURRENCY += int((selected_item.VALUE * sell_modifier) * amount)
			loadWares(PlayerGlobals.INVENTORY)

func _on_toggle_mode_pressed():
	match mode:
		1:
			mode = 0
			loadWares(PlayerGlobals.INVENTORY)
		0: 
			mode = 1
			loadWares(wares_array)
