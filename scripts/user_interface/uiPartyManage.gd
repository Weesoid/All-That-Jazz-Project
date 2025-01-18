extends MemberAdjustUI

@onready var member_view = $Label/Marker2D
@onready var currency = $Currency
@onready var debug_button = $GetAllCombatants
#@onready var experience_bar = $TabContainer/Temperment/ProgressBar
#@onready var reroll_primary = $TabContainer/Temperment/VBoxContainer/HSplitContainer/RerollPrimary
#@onready var reroll_secondary = $TabContainer/Temperment/VBoxContainer/HSplitContainer2/RerollSecondary
#@onready var primary_name = $TabContainer/Temperment/VBoxContainer/HSplitContainer/HBoxContainer/Label
#@onready var primary_val = $TabContainer/Temperment/VBoxContainer/HSplitContainer/HBoxContainer/Label2
#@onready var secondary_name = $TabContainer/Temperment/VBoxContainer/HSplitContainer2/HBoxContainer/Label
#@onready var secondary_val = $TabContainer/Temperment/VBoxContainer/HSplitContainer2/HBoxContainer/Label2
#@onready var reroll_cost = $TabContainer/Temperment/ProgressBar/Label
#@onready var reroll_button = $TabContainer/Temperment/VBoxContainer/HSplitContainer2/RerollSecondary

func _ready():
	loadMembers()
	if !PlayerGlobals.TEAM.is_empty():
		for member in PlayerGlobals.TEAM: loadMemberInfo(member)
	if OverworldGlobals.isPlayerCheating():
		debug_button.show()

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
	for child in member_view.get_children():
		child.queue_free()
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
		loadAbilities()
		updateEquipped()
	updateTemperments()

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


func _on_get_all_combatants_pressed():
	addAllMembers("res://resources/combat/combatants_player/tameable/")
	loadMembers(true)

func _on_reroll_primary_pressed():
	var cost = int(PlayerGlobals.getRequiredExp()*0.05)
	if PlayerGlobals.CURRENT_EXP >= cost:
		rerollTemperment('primary', cost)
	else:
		reroll_primary.disabled = true

func _on_reroll_secondary_pressed():
	var cost = int(PlayerGlobals.getRequiredExp()*0.05)
	if PlayerGlobals.CURRENT_EXP >= cost:
		rerollTemperment('secondary', cost)
	else:
		reroll_secondary.disabled = true

func rerollTemperment(type: String, cost):
	PlayerGlobals.addExperience(-cost, false)
	var valid_temperments
	if type == 'primary':
		valid_temperments = PlayerGlobals.PRIMARY_TEMPERMENTS.keys().filter(func(temperment): return temperment != selected_combatant.TEMPERMENT[type])
		selected_combatant.TEMPERMENT[type] = valid_temperments.pick_random()
	elif type == 'secondary':
		valid_temperments = PlayerGlobals.SECONDARY_TEMPERMENTS.keys().filter(func(temperment): return temperment != selected_combatant.TEMPERMENT[type])
		selected_combatant.TEMPERMENT[type] = valid_temperments.pick_random()
	updateExpBar(true)
	updateTemperments()
	reroll_primary.disabled = PlayerGlobals.CURRENT_EXP < cost
	reroll_secondary.disabled = PlayerGlobals.CURRENT_EXP < cost

func updateExpBar(show_tween:bool=false):
	experience_bar.max_value = PlayerGlobals.getRequiredExp()
	experience_bar.value = PlayerGlobals.CURRENT_EXP
	if show_tween:
		var tween = create_tween()
		tween.tween_property(experience_bar,'modulate',Color.RED,0.1)
		tween.tween_property(experience_bar,'modulate',Color.WHITE,0.15)

func updateTemperments():
	selected_combatant.applyTemperments(true)
	var cost = int(PlayerGlobals.getRequiredExp()*0.05)
	reroll_cost.text = 'Morale Cost: %s' % str(cost)
	reroll_primary.disabled = PlayerGlobals.CURRENT_EXP < cost
	primary_name.text = selected_combatant.TEMPERMENT['primary'].capitalize().replace('_', '')
	secondary_name.text = selected_combatant.TEMPERMENT['secondary'].capitalize().replace('_', '')
	primary_val.text = formatModifiers(selected_combatant.STAT_MODIFIERS['primary_temperment'])
	secondary_val.text = formatModifiers(selected_combatant.STAT_MODIFIERS['secondary_temperment'])
	if selected_combatant.hasEquippedWeapon() and !selected_combatant.EQUIPPED_WEAPON.canUse(selected_combatant):
		selected_combatant.unequipWeapon()

func formatModifiers(stat_dict: Dictionary) -> String:
	var result = ""
	for key in stat_dict.keys():
		var value = stat_dict[key]
		if value is float: 
			value *= 100.0
		if stat_dict[key] > 0 and stat_dict[key]:
			result += '[color=GREEN_YELLOW]'
			if value is float: 
				result += "+" + str(value) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(value) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			result += '[color=ORANGE_RED]'
			if value is float: 
				result += str(value) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(value) + " " +key.to_upper().replace('_', ' ') + "\n"
		result += '[/color]'
	return result

func _on_tab_container_tab_changed(tab):
	print(tab)
	select_charms_panel.hide()
	if tab == 0:
		loadAbilities()
	elif tab == 1:
		select_charms_panel.hide()
		charm_info_panel.hide()
		setFocusMode(equipped_charms, true)
		setFocusMode(member_container, true)
		weapon_button.grab_focus()
	
	match tab:
		0: 
			OverworldGlobals.setMenuFocus(pool)
		1: 
			OverworldGlobals.setMenuFocus(equipped_charms)
			if !selected_combatant.hasEquippedWeapon():
				weapon_button.icon = null
				weapon_button.text = 'Unarmed'
		2: 
			attrib_adjust.focus()
		3: 
			var cost = int(PlayerGlobals.getRequiredExp()*0.05)
			updateExpBar()
			updateTemperments()
			reroll_primary.disabled = PlayerGlobals.CURRENT_EXP < cost
			reroll_secondary.disabled = PlayerGlobals.CURRENT_EXP < cost
			reroll_button.grab_focus()
