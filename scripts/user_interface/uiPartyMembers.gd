extends Control

@onready var member_container = $Members/HBoxContainer
@onready var base = $Members
func _ready():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var member_button = Button.new()
		member_button.text = member.NAME
		member_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		member_button.custom_minimum_size.x = 96
		member_button.pressed.connect(
			func loadMemberInformation():
				var ui = load("res://scenes/user_interface/CharacterInfo.tscn").instantiate()
				ui.subject_combatant = member
				base.modulate.a = 0
				add_child(ui)
				print('Done!')
		)
		member_container.add_child(member_button)
