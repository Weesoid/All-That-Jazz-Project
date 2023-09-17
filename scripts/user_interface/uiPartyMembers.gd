extends Control

@onready var member_container = $Members/HBoxContainer
@onready var base = $Members
@onready var info = $uiCharacterInformation
func _ready():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var member_button = Button.new()
		member_button.text = member.NAME
		member_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		member_button.custom_minimum_size.x = 96
		member_button.pressed.connect(
			func loadMemberInformation():
				info.subject_combatant = member
				info.loadInformation()
		)
		member_container.add_child(member_button)
