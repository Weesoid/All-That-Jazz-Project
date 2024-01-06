extends Control

@onready var current_members = $CurrentMembers/VBoxContainer
@onready var benched_members = $BenchedMembers/ScrollContainer/VBoxContainer
@onready var info = $uiCharacterInformation

func _ready():
	for member in PlayerGlobals.TEAM:
		var button = Button.new()
		button.text = member.NAME
		button.icon = member.ICON
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(
			func addToAcitve():
				if !OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member):
					OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.append(member)
					member.active = true
					OverworldGlobals.initializePlayerParty()
					benched_members.remove_child(button)
					current_members.add_child(button)
				else:
					OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.erase(member)
					member.unequipGear()
					member.active = false
					PlayerGlobals.removeFollower(member)
					current_members.remove_child(button)
					benched_members.add_child(button)
		)
		button.mouse_entered.connect(
			func updateInfo():
				info.subject_combatant = member
				info.loadInformation()
		)
		if member.MANDATORY and member.active: 
			button.disabled = true
		if member.active:
			current_members.add_child(button)
		else:
			benched_members.add_child(button)
