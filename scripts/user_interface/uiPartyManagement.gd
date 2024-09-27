extends Control

@onready var inspecting_name = $Label
@onready var members = $BenchedMembers/ScrollContainer/VBoxContainer
@onready var info = $uiCharacterInformation

func _ready():
	if OverworldGlobals.isPlayerCheating():
		addAllMembers()
		await get_tree().create_timer(0.01).timeout
	
	for member in PlayerGlobals.TEAM:
		if !member.initialized: member.initializeCombatant(false)
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
		button.focus_entered.connect(func(): updateInfo(member))
		if member.MANDATORY and member.active: 
			button.disabled = true
		if member.active:
			button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
		else:
			button.remove_theme_icon_override('icon')
		
		members.add_child(button)
	
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		updateInfo(OverworldGlobals.getCombatantSquad('Player')[0])
	OverworldGlobals.setMenuFocus(members)

func addAllMembers():
	var path = "res://resources/combat/combatants_player/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var combatant = load(path+'/'+file_name)
			if !PlayerGlobals.TEAM.has(combatant):
				PlayerGlobals.addCombatantToTeam(combatant)
			file_name = dir.get_next()
			#print(file_name)
	else:
		print("An error occurred when trying to access the path.")
		print(path)

func updateInfo(member: ResCombatant):
	inspecting_name.text = member.NAME
	info.subject_combatant = member
	info.loadInformation()
	info.show()

func _on_tab_container_tab_changed(_tab):
	if info.tabs.current_tab == 0:
		for button in members.get_children():
			if button.text == info.subject_combatant.NAME:
				button.grab_focus()
				return
