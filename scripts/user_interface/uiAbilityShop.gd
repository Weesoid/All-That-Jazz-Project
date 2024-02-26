extends Control

@onready var pool = $Pool/Scroll/VBoxContainer
@onready var abilities = $Abilities/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
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
				selected_combatant = member
				loadAbilities()
		)
		member_container.add_child(member_button)

func loadAbilities():
	clearButtons()
	for ability in selected_combatant.ABILITY_POOL:
		if PlayerGlobals.PARTY_LEVEL < ability.REQUIRED_LEVEL: continue
		createButton(ability, pool)
	for ability in selected_combatant.ABILITY_SET:
		createButton(ability, abilities)

func clearButtons():
	for child in abilities.get_children():
		child.queue_free()
	for chid in pool.get_children():
		chid.queue_free()

func createButton(ability, location):
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.x = 170
	button.text = ability.NAME
	button.pressed.connect(
		func transferItem():
			if selected_combatant.ABILITY_POOL.has(ability):
				if selected_combatant.ABILITY_SET.size() + 1 > 4:
					return
				selected_combatant.ABILITY_POOL.erase(ability)
				selected_combatant.ABILITY_SET.append(ability)
				loadAbilities()
			elif selected_combatant.ABILITY_SET.has(ability):
				selected_combatant.ABILITY_SET.erase(ability)
				selected_combatant.ABILITY_POOL.append(ability)
				loadAbilities()
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.DESCRIPTION
	)
	location.add_child(button)
