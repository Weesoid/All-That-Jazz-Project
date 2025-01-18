extends PanelContainer
class_name RosterSelector

@onready var member_container = $ScrollContainer/HBoxContainer

func _process(_delta):
	if get_parent() != null and get_parent().changing_formation:
		hide()
	elif get_parent() != null:
		show()

func _ready():
	loadMembers()

func loadMembers():
	for member in PlayerGlobals.TEAM:
		var member_button = createMemberButton(member)
		member_container.add_child(member_button)

func createMemberButton(member: ResCombatant):
	var button = OverworldGlobals.createCustomButton()
	#button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
	button.text = member.NAME
	button.pressed.connect(func(): addToActive(member, button))
	if OverworldGlobals.getCombatantSquad('Player').has(member):
		button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	else:
		button.remove_theme_icon_override('icon')
	if member.MANDATORY and member.active: 
		button.disabled = true
	return button

func addToActive(member: ResCombatant, button: Button):
	if OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.size() == 4 and !OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member):
		OverworldGlobals.showPlayerPrompt('You have a full party!')
		return
	
	if !OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member) and button != null:
		OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.append(member)
		OverworldGlobals.initializePlayerParty()
		button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	elif button != null:
		OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.erase(member)
		PlayerGlobals.removeFollower()
		button.remove_theme_icon_override('icon')
	PlayerGlobals.TEAM_FORMATION = OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD
	await get_tree().process_frame
	get_parent().loadMembers()
