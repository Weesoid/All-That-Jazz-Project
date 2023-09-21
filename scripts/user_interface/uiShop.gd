extends Control

@onready var wares = $Wares/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var stats = $StatsPanel/Label
@onready var action_button = $Action
@onready var toggle_button = $ToggleMode
@onready var currency = $Currency

var wares_array
var barter_array

var mode = 1
var selected_item
var selected_combatant: ResPlayerCombatant
var buy_modifier = 1.0
var sell_modifier = 0.5

func _ready():
	loadWares()

func _process(_delta):
	currency.text = str(PlayerGlobals.CURRENCY)

func loadWares(array=wares_array):
	clearButtons()
	action_button.disabled = true
	if mode == 1:
		action_button.text = 'Purchase'
		toggle_button.text = 'Barter'
	elif mode == 0:
		action_button.text = 'Sell'
		toggle_button.text = 'Shop'
	
	for item in array:
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s (%s)" % [item, item.VALUE]
		
		if item is ResEquippable and !PlayerGlobals.canAdd(item): # TO DO Add no show prompt
			button.disabled = true
		
		button.pressed.connect(
			func setSelected():
				selected_item = item
				if PlayerGlobals.CURRENCY < selected_item.VALUE * buy_modifier:
					action_button.disabled = true
				else:
					action_button.disabled = false
		)
		wares.add_child(button)

func clearButtons():
	for child in wares.get_children():
		child.queue_free()

func _on_action_pressed():
	match mode:
		1:
			if selected_item is ResItem:
				PlayerGlobals.CURRENCY -= selected_item.VALUE * buy_modifier
				PlayerGlobals.addItemResource(selected_item)
			elif selected_item is ResAbility:
				selected_combatant.SKILL_POINTS -= selected_item.VALUE
				selected_combatant.ABILITY_SET.append(selected_item)
			loadWares(wares_array)
		0:
			if selected_item is ResItem:
				PlayerGlobals.CURRENCY += selected_item.VALUE * sell_modifier
				PlayerGlobals.removeItemResource(selected_item)
			elif selected_item is ResAbility:
				selected_combatant.SKILL_POINTS += selected_item.VALUE
				selected_combatant.ABILITY_SET.erase(selected_item)
			loadWares(barter_array)

func _on_toggle_mode_pressed():
	match mode:
		1: 
			mode = 0
			loadWares(barter_array)
		0: 
			mode = 1
			loadWares(wares_array)
