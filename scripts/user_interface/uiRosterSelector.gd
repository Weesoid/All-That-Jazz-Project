extends Control
class_name RosterSelector

@onready var member_container = $ScrollContainer/HBoxContainer
@onready var inspecting_label = $Label
@onready var inspect_mark = $InspectIcon

func _process(_delta):
	if get_parent() != null and get_parent().changing_formation:
		hide()
	elif get_parent() != null:
		show()

func _ready():
	loadMembers()

func loadMembers():
	var team = PlayerGlobals.TEAM
	team.sort_custom(func(a,b): return a.NAME < b.NAME)
	team.sort_custom(func(a,b): return isMemberMandatory(a) > isMemberMandatory(b))
	for member in team:
		var member_button = createMemberButton(member)
		member_container.add_child(member_button)

func isMemberMandatory(member: ResPlayerCombatant):
	match member.MANDATORY:
		true: return 1
		false: return 0

func createMemberButton(member: ResPlayerCombatant):
	member.initializeCombatant(false)
	var button = OverworldGlobals.createCustomButton()
	#button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
	button.text = member.NAME
	button.pressed.connect(func(): addToActive(member, button))
#	button.mouse_exited.connect(func(): inspecting_label.text = '')
#	button.focus_exited.connect(func(): inspecting_label.text = '')
	button.focus_entered.connect(func(): hoverButton(member, button))
	button.mouse_entered.connect(func(): hoverButton(member, button))
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
		OverworldGlobals.showPrompt('You have a full party!')
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
		#PlayerGlobals.removeFollower()
		OverworldGlobals.loadFollowers()
		if member.isInflicted() and !OverworldGlobals.getCombatantSquad('Player').has(member):
			button.add_theme_icon_override('icon', preload("res://images/sprites/inflicted_icon.png"))
		else:
			button.remove_theme_icon_override('icon')
	PlayerGlobals.TEAM_FORMATION = OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD
	await get_tree().process_frame
	get_parent().loadMembers()

func hoverButton(member: ResPlayerCombatant, button: Button):
	if Input.is_action_pressed('ui_sprint'):
		if OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.has(member):
			for mem_button in get_parent().member_container.get_children():
				if mem_button.text == member.NAME:
					inspect_mark.hide()
					mem_button.pressed.emit()
					return
		else:
			get_parent().loadMemberInfo(member)
			inspect_mark.show()
			inspect_mark.global_position = button.global_position+Vector2(button.size.x-2, button.size.y/8)
#			for body in get_parent().getOtherMemberScenes():
#				body.modulate = Color(Color.WHITE, 0.25)
#				body.combatant_resource.getAnimator().play('RESET')
#				body.combatant_resource.stopBreatheTween()
