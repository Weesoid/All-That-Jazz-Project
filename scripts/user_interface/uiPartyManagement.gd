extends Control

@onready var inspecting_name = $Label
@onready var members = $BenchedMembers/ScrollContainer/VBoxContainer
@onready var info = $uiCharacterInformation

func _ready():
	for member in PlayerGlobals.TEAM:
		var button = OverworldGlobals.createCustomButton()
		button.text = member.NAME
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(
			func addToAcitve():
				if !OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member):
					OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.append(member)
					member.active = true
					OverworldGlobals.initializePlayerParty()
					button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
				else:
					OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.erase(member)
					PlayerGlobals.removeFollower(member)
					button.remove_theme_icon_override('icon')
		)
		button.mouse_entered.connect(func(): updateInfo(member))
		if member.MANDATORY and member.active: 
			button.disabled = true
		if member.active:
			button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
		else:
			button.remove_theme_icon_override('icon')
		
		members.add_child(button)
	
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		updateInfo(OverworldGlobals.getCombatantSquad('Player')[0])

func updateInfo(member: ResCombatant):
	inspecting_name.text = member.NAME
	info.subject_combatant = member
	info.loadInformation()
	info.show()
