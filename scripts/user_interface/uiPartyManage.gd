extends MemberAdjustUI

@onready var member_view = $Label/Marker2D
@onready var currency = $Currency

func _ready():
	if OverworldGlobals.isPlayerCheating():
		addAllMembers("res://resources/combat/combatants_player/tameable/")
		await get_tree().create_timer(0.01).timeout
	
	loadMembers()
	if !PlayerGlobals.TEAM.is_empty():
		for member in PlayerGlobals.TEAM: loadMemberInfo(member)

func loadMembers(set_focus:bool=true):
	for child in member_container.get_children():
		child.queue_free()
	
	for member in PlayerGlobals.TEAM:
		var member_button = createMemberButton(member)
		member_container.add_child(member_button)
		if set_focus:
			member_button.grab_focus()
			selected_combatant = member
			loadMemberInfo(selected_combatant)
			set_focus = false

func createMemberButton(member: ResCombatant):
	var button = OverworldGlobals.createCustomButton()
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
	button.text = member.NAME
	button.pressed.connect(func(): 
		loadMemberInfo(member, button)
		addToActive(member, button)
		)
	button.focus_entered.connect(func(): loadMemberInfo(member, button))
	button.mouse_entered.connect(func(): loadMemberInfo(member, button))
	if OverworldGlobals.getCombatantSquad('Player').has(member):
		button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	else:
		button.remove_theme_icon_override('icon')
	if member.MANDATORY and member.active: 
		button.disabled = true
	return button

func loadMemberInfo(member: ResCombatant, button: Button=null):
	if member_view.get_children().size() > 0 and member_view.get_child(0) != null and member_view.get_child(0) != member.SCENE:
		member_view.get_child(0).queue_free()
	member.initializeCombatant()
	member_view.add_child(member.SCENE)
	member.SCENE.playIdle()
	
	if changing_formation and selected_combatant == null:
		selected_combatant = member
		button.add_theme_color_override('font_color', Color.YELLOW)
		button.add_theme_color_override('border_color', Color.YELLOW)
	elif changing_formation and selected_combatant != null:
		swapMembers(selected_combatant, member)
		loadMembers(false)
		await get_tree().process_frame
		for child in member_container.get_children():
			if child.text == selected_combatant.NAME: 
				child.grab_focus()
				break
		selected_combatant = null
	else:
		selected_combatant = member
		select_charms_panel.hide()
		member_name.text = member.NAME
		loadAbilities()
		updateEquipped()

func createButton(ability:ResAbility, location):
	if ability.REQUIRED_LEVEL > PlayerGlobals.PARTY_LEVEL:
		return
	
	var button: CustomButton = OverworldGlobals.createCustomButton()
	var has_unlocked = PlayerGlobals.hasUnlockedAbility(selected_combatant, ability) or ability.REQUIRED_LEVEL == 0
	button.focused_entered_sound = preload("res://audio/sounds/421354__jaszunio15__click_31.ogg")
	button.click_sound = preload("res://audio/sounds/421304__jaszunio15__click_229.ogg")
	button.text = ability.NAME
	if !has_unlocked:
		button.text += ' ('+str(ability.getCost())+')'
	
	if selected_combatant.ABILITY_SET.has(ability):
		button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	elif !has_unlocked:
		button.add_theme_icon_override('icon', preload("res://images/sprites/lock.png"))
		button.add_theme_color_override('font_color', Color.DIM_GRAY)
	if !has_unlocked and ability.getCost() > PlayerGlobals.CURRENCY:
		button.add_theme_color_override('font_color', Color.RED)
	
	button.pressed.connect(
		func():
			if has_unlocked:
				if !selected_combatant.ABILITY_SET.has(ability):
					if selected_combatant.ABILITY_SET.size() >= 4:
						OverworldGlobals.showPlayerPrompt('Max abilities enabled.')
						return
					selected_combatant.ABILITY_SET.append(ability)
					button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
				elif selected_combatant.ABILITY_SET.has(ability):
					selected_combatant.ABILITY_SET.erase(ability)
					button.remove_theme_icon_override('icon')
			else:
				if button.has_focus() and PlayerGlobals.CURRENCY >= ability.getCost():
					PlayerGlobals.CURRENCY -= ability.getCost()
					PlayerGlobals.unlockAbility(selected_combatant, ability)
					OverworldGlobals.playSound('res://audio/sounds/721774__maodin204__cash-register.ogg')
					loadMemberInfo(selected_combatant)
	)
	button.focus_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.getRichDescription()
			if !has_unlocked: 
				currency.show()
			else:
				currency.hide()
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.getRichDescription()
			if !has_unlocked: 
				currency.show()
			else:
				currency.hide()
	)
	location.add_child(button)

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

func loadAbilities():
	clearButtons()
	if selected_combatant.ABILITY_POOL.is_empty():
		return
	
	for ability in selected_combatant.ABILITY_POOL:
		if ability == null:
			selected_combatant.ABILITY_POOL.erase(ability)
			continue
		if PlayerGlobals.PARTY_LEVEL < ability.REQUIRED_LEVEL: 
			continue
		createButton(ability, pool)

func addAllMembers(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var combatant = load(path+'/'+file_name)
			if !PlayerGlobals.TEAM.has(combatant):
				PlayerGlobals.addCombatantToTeam(combatant)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
