extends Control

@onready var abilities = $Abilities/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var toggle_button = $ToggleMode
@onready var currency = $Currency
@onready var member_container = $Members/HBoxContainer
@onready var combatant_name = $CombatantName

var mode = 1
var selected_combatant: ResPlayerCombatant

func _ready():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var member_button = Button.new()
		member_button.text = member.NAME
		member_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		member_button.custom_minimum_size.x = 96
		member_button.pressed.connect(
			func loadMemberInformation():
				toggle_button.disabled = false
				selected_combatant = member
				mode = 1
				loadAbilities(selected_combatant.ABILITY_POO)
		)
		member_container.add_child(member_button)

func _process(_delta):
	match mode:
		1: toggle_button.text = 'MODE: ASSOCIATION'
		0: toggle_button.text = 'MODE: DISSOCIATION'
	
	if selected_combatant != null:
		combatant_name.text = selected_combatant.NAME
		currency.text = str(selected_combatant.ABILITY_POINTS) + ' SP'

func loadAbilities(ability_array):
	clearButtons()
	for ability in ability_array:
		if ability == ability_array[0]:
			continue
		if selected_combatant.ABILITY_SET.has(ability) and mode == 1: 
			continue

		
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x = 360
		button.text = "%s (%s)" % [ability.NAME, ability.VALUE]
		button.pressed.connect(
			func():
				if mode == 1:
					selected_combatant.ABILITY_POO.erase(ability)
					selected_combatant.ABILITY_SET.append(ability)
					selected_combatant.ABILITY_POINTS -= ability.VALUE
					loadAbilities(selected_combatant.ABILITY_POO)
				elif mode == 0:
					selected_combatant.ABILITY_SET.erase(ability)
					selected_combatant.ABILITY_POO.append(ability)
					selected_combatant.ABILITY_POINTS += ability.VALUE
					loadAbilities(selected_combatant.ABILITY_SET)
					
		)
		button.mouse_entered.connect(
			func updateDescription():
				description.text = '' 
				description.text = ability.DESCRIPTION
		)
		if ability.VALUE > selected_combatant.ABILITY_POINTS and mode == 1:
			button.disabled = true
		abilities.add_child(button)

func clearButtons():
	for child in abilities.get_children():
		child.queue_free()

func _on_toggle_mode_pressed():
	match mode:
		1:
			mode = 0
			loadAbilities(selected_combatant.ABILITY_SET)
		0: 
			mode = 1
			loadAbilities(selected_combatant.ABILITY_POO)
