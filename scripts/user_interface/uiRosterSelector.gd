extends Control
class_name RosterSelector

@onready var member_container = $ScrollContainer/HBoxContainer
@onready var inspecting_label = $Label

func _process(_delta):
	if get_parent() != null and get_parent().changing_formation:
		hide()
	elif get_parent() != null:
		show()
	
#	if !get_parent().changing_formation:
#		if !OverworldGlobals.getCombatantSquad('Player').has(get_parent().selected_combatant):
#			for member in member_container.get_children():
#				if member.text == get_parent().selected_combatant.NAME:
#					member.add_theme_icon_override('icon', preload("res://images/sprites/inspect_mark.png"))
#				elif !OverworldGlobals.getCombatantSquadComponent('Player').hasMember(member.text) and !PlayerGlobals.getTeamMember(member.text).isInflicted():
#					member.remove_theme_icon_override('icon')
#		else:
#			for member in member_container.get_children():
#				if !OverworldGlobals.getCombatantSquadComponent('Player').hasMember(member.text) and PlayerGlobals.getTeamMember(member.text).isInflicted():
#					member.add_theme_icon_override('icon', preload("res://images/sprites/inflicted_icon.png"))
#				elif !OverworldGlobals.getCombatantSquadComponent('Player').hasMember(member.text):
#					member.remove_theme_icon_override('icon')
#	if OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(get_parent().selected_combatant):
#		inspecting_label.hide()

func _ready():
	loadMembers()

func loadMembers():
	for member in PlayerGlobals.TEAM:
		var member_button = createMemberButton(member)
		member_container.add_child(member_button)

func createMemberButton(member: ResPlayerCombatant):
	member.initializeCombatant(false)
	var button = OverworldGlobals.createCustomButton()
	#button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
	button.text = member.NAME
	button.pressed.connect(func(): addToActive(member, button))
#	button.mouse_exited.connect(func(): inspecting_label.text = '')
#	button.focus_exited.connect(func(): inspecting_label.text = '')
	button.focus_entered.connect(func(): hoverButton(member))
	button.mouse_entered.connect(func(): hoverButton(member))
	print(member.isInflicted())
	if OverworldGlobals.getCombatantSquad('Player').has(member):
		if member.isInflicted():
			button.add_theme_icon_override('icon', preload("res://images/sprites/inflicted_mark.png"))
		else:
			button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	else:
		button.remove_theme_icon_override('icon')
	if member.isInflicted() and !OverworldGlobals.getCombatantSquad('Player').has(member):
		button.add_theme_icon_override('icon', preload("res://images/sprites/inflicted_icon.png"))
	if member.MANDATORY and OverworldGlobals.getCombatantSquadComponent('Player').hasMember(member.NAME): 
		button.disabled = true
	return button

func addToActive(member: ResCombatant, button: Button):
	if OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.size() == 4 and !OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member):
		OverworldGlobals.showPlayerPrompt('You have a full party!')
		return
	
	if !OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member) and button != null:
		OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.append(member)
		OverworldGlobals.initializePlayerParty()
		if member.isInflicted():
			button.add_theme_icon_override('icon', preload("res://images/sprites/inflicted_mark.png"))
		else:
			button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	elif button != null:
		OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.erase(member)
		PlayerGlobals.removeFollower()
		if member.isInflicted() and !OverworldGlobals.getCombatantSquad('Player').has(member):
			button.add_theme_icon_override('icon', preload("res://images/sprites/inflicted_icon.png"))
		else:
			button.remove_theme_icon_override('icon')
	PlayerGlobals.TEAM_FORMATION = OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD
	await get_tree().process_frame
	get_parent().loadMembers()

func hoverButton(member: ResPlayerCombatant):
	if Input.is_action_pressed('ui_sprint'):
		if OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member):
			for mem_button in get_parent().member_container.get_children():
				if mem_button.text == member.NAME: 
					mem_button.pressed.emit()
					return
		else:
			get_parent().loadMemberInfo(member)
			for body in get_parent().getOtherMemberScenes():
				body.modulate = Color(Color.WHITE, 0.25)
				body.combatant_resource.getAnimator().play('RESET')
				body.combatant_resource.stopBreatheTween()
