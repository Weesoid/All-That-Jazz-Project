# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var character_name = $CharacterName
@onready var description = $Description/DescriptionLabel
@onready var stat_panel = $Stats/Label
@onready var ability_panel = $Abilities/ScrollContainer/VBoxContainer
@onready var equipment_panel = $Equipment/ScrollContainer/VBoxContainer

var subject_combatant: ResCombatant

func _ready():
	character_name.text = subject_combatant.NAME
	stat_panel.text = subject_combatant.getStringStats()
	print(stat_panel.text)
	description.text = subject_combatant.DESCRIPTION
	
	for ability in subject_combatant.ABILITY_SET:
		var ability_button = Button.new()
		ability_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ability_button.text = ability.NAME
		ability_button.pressed.connect(
			func updateDesciption():
				description.text = ability.DESCRIPTION
		)
		ability_panel.add_child(ability_button)
	
	for equipment in subject_combatant.EQUIPMENT.values():
		if equipment == null:
			var equipment_button = Button.new()
			equipment_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			equipment_button.text = str('Not equipped')
			equipment_panel.add_child(equipment_button)
			continue
		
		var equipment_button = Button.new()
		equipment_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		equipment_button.text = equipment.NAME
		equipment_button.pressed.connect(
		func updateDesciption():
			description.text = equipment.getStringStats()
		)
		equipment_panel.add_child(equipment_button)
	
	stat_panel.text = subject_combatant.getStringStats()
