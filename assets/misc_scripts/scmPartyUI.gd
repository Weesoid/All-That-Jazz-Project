extends Control

@onready var party_panel = $PartyPanel/ScrollContainer/VBoxContainer
@onready var stat_panel = $StatPanel/DescriptionLabel
@onready var ability_panel = $SkillPanel/ScrollContainer/VBoxContainer
@onready var member_description = $MemberDescription/DescriptionLabel
@onready var skill_description = $SkillDescription/DescriptionLabel

var selected_combatant: ResCombatant

func _ready():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var button = Button.new()
		button.text = member.NAME
		button.pressed.connect(
			func updateMemberInfo(): 
				stat_panel.text = member.getStringStats()
				member_description.text = member.DESCRIPTION
				for child in ability_panel.get_children():
					child.free()
					
				for ability in member.ABILITY_SET:
					var ability_button = Button.new()
					ability_button.text = ability.NAME
					ability_panel.add_child(ability_button)
				)
		party_panel.add_child(button)
	
