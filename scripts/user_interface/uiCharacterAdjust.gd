extends Control
class_name MemberAdjustUI

@onready var tabs = $TabContainer
@onready var pool = $TabContainer/Abilities/ScrollContainer/VBoxContainer
@onready var description = $TabContainer/Abilities/DescriptionPanel/Label
@onready var member_container = $Members/HBoxContainer
@onready var attrib_adjust = $TabContainer/Attributes
@onready var attrib_view = $AttributeView
@onready var equipped_charms = $TabContainer/Charms/EquippedCharms
@onready var select_charms = $TabContainer/Charms/Panel/SelectCharms/VBoxContainer
@onready var select_charms_panel = $TabContainer/Charms/Panel
@onready var charm_info_panel = $TabContainer/Charms/Infomration
@onready var charm_description = $TabContainer/Charms/Infomration/ItemInfo/DescriptionLabel2
@onready var charm_description_general = $TabContainer/Charms/Infomration/GeneralInfo
@onready var weapon_button = $TabContainer/Charms/EquippedCharms/Weapon
@onready var charm_slot_a = $TabContainer/Charms/EquippedCharms/SlotA
@onready var charm_slot_b = $TabContainer/Charms/EquippedCharms/SlotB
@onready var charm_slot_c = $TabContainer/Charms/EquippedCharms/SlotC
@onready var member_name = $Label
@onready var formation_button = $ChangeFormation
@onready var infliction = $Infliction
var selected_combatant: ResPlayerCombatant
var changing_formation: bool = false

func _process(_delta):
	if selected_combatant != null:
		attrib_view.combatant = selected_combatant
		attrib_adjust.combatant = selected_combatant
		if selected_combatant.isInflicted():
			infliction.text = 'INFLICTED!'
			infliction.add_theme_color_override("font_color", Color.ORANGE)
			infliction.tooltip_text = selected_combatant.getLingeringEffectsString()
		else:
			infliction.add_theme_color_override("font_color", Color.WHITE)
			infliction.text = ''
			infliction.tooltip_text = ''

func _ready():
	loadMembers()
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		loadMemberInfo(OverworldGlobals.getCombatantSquad('Player')[0])

func loadMembers(set_focus:bool=true):
	for child in member_container.get_children():
		child.queue_free()
	
	for i in range(OverworldGlobals.getCombatantSquad('Player').size(), 0, -1):
		var member = OverworldGlobals.getCombatantSquad('Player')[i-1]
		var member_button = createMemberButton(member)
		member_container.add_child(member_button)
		if i == 1 and set_focus:
			member_button.grab_focus()
			selected_combatant = member
			loadMemberInfo(selected_combatant)
	
	for body in getOtherMemberScenes(selected_combatant.NAME):
		body.modulate = Color(Color.WHITE, 0.25)

func loadMemberInfo(member: ResCombatant, button: Button=null):
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
		for body in getOtherMemberScenes(): body.modulate = Color(Color.WHITE, 1.0)
		selected_combatant = null
	else:
		selected_combatant = member
		select_charms_panel.hide()
		member_name.text = member.NAME
		loadAbilities()
		updateEquipped()
	
	#print(selected_combatant.TEMPERMENT)

func swapMembers(member_a: ResCombatant, member_b: ResCombatant):
	var team = OverworldGlobals.getCombatantSquad('Player')
	var member_a_pos = team.find(member_a)
	team[team.find(member_b)] = member_a
	team[member_a_pos] = member_b

func loadAbilities():
	clearButtons()
	if selected_combatant.ABILITY_POOL.is_empty():
		return
	
	for ability in selected_combatant.ABILITY_POOL:
		if ability == null:
			selected_combatant.ABILITY_POOL.erase(ability)
			continue
		if PlayerGlobals.PARTY_LEVEL < ability.REQUIRED_LEVEL or !PlayerGlobals.hasUnlockedAbility(selected_combatant, ability): 
			continue
		createButton(ability, pool)

func clearButtons():
	for chid in pool.get_children():
		pool.remove_child(chid)
		chid.queue_free()
	for child in select_charms.get_children():
		select_charms.remove_child(child)
		child.queue_free()

func createButton(ability, location):
	var button: CustomButton = OverworldGlobals.createCustomButton()
	button.custom_minimum_size.x = 130
	button.focused_entered_sound = preload("res://audio/sounds/421354__jaszunio15__click_31.ogg")
	button.click_sound = preload("res://audio/sounds/421304__jaszunio15__click_229.ogg")
	button.text = ability.NAME
	if selected_combatant.ABILITY_SET.has(ability):
		button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
	
	button.pressed.connect(
		func():
			if !selected_combatant.ABILITY_SET.has(ability):
				if selected_combatant.ABILITY_SET.size() >= 4:
					OverworldGlobals.showPlayerPrompt('Max abilities enabled.')
					return
				selected_combatant.ABILITY_SET.append(ability)
				button.add_theme_icon_override('icon', preload("res://images/sprites/icon_mark.png"))
			elif selected_combatant.ABILITY_SET.has(ability):
				selected_combatant.ABILITY_SET.erase(ability)
				button.remove_theme_icon_override('icon')
	)
	button.focus_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.getRichDescription()
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.getRichDescription()
	)
	location.add_child(button)

func createMemberButton(member: ResCombatant):
	var button = OverworldGlobals.createCustomButton(load("res://design/PartyButtons.tres"))
	button.alignment =HORIZONTAL_ALIGNMENT_RIGHT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
	button.custom_minimum_size.x = 64
	button.text = member.NAME
	member.initializeCombatant()
	member.getAnimator().play('Idle')
	button.add_child(member.SCENE)
	button.pressed.connect(
		func():
			member.SCENE.modulate = Color(Color.WHITE, 1.0)
			for body in getOtherMemberScenes(member.NAME):
				body.modulate = Color(Color.WHITE, 0.25)
			loadMemberInfo(member, button)
			)
#	button.focus_entered.connect(func(): member.SCENE.modulate = Color.YELLOW)
#	button.mouse_entered.connect(func(): member.SCENE.modulate = Color.YELLOW)
#	button.focus_exited.connect(func(): member.SCENE.modulate = Color.WHITE)
#	button.mouse_exited.connect(func(): member.SCENE.modulate = Color.WHITE)
	return button

func getOtherMemberScenes(except_name: String=''):
	var out = []
	for body in member_container.get_children():
		if body.text == except_name and except_name != '': continue
		out.append(body.get_node('CharacterBody2D'))
	return out

func showCharmEquipMenu(slot_button: Button):
	setFocusMode(equipped_charms, false)
	setFocusMode(member_container, false)
	clearButtons()
	select_charms_panel.show()
	var unequip_button = OverworldGlobals.createCustomButton()
	unequip_button.theme = preload("res://design/ItemButtons.tres")
	unequip_button.icon = preload('res://images/sprites/icon_cross.png')
	unequip_button.focused_entered_sound = preload("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	unequip_button.click_sound = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")
	unequip_button.pressed.connect(
		func():
			if slot_button == charm_slot_a:
				selected_combatant.unequipCharm(0)
			elif slot_button == charm_slot_b:
				selected_combatant.unequipCharm(1)
			elif slot_button == charm_slot_c:
				selected_combatant.unequipCharm(2)
			slot_button.icon = preload("res://images/sprites/icon_plus.png")
			select_charms_panel.hide()
			charm_info_panel.hide()
			setFocusMode(equipped_charms, true)
			setFocusMode(member_container, true)
			if slot_button == charm_slot_a:
				charm_slot_a.grab_focus()
			elif slot_button == charm_slot_b:
				charm_slot_b.grab_focus()
			elif slot_button == charm_slot_c:
				charm_slot_c.grab_focus()
	)
	unequip_button.connect('focus_entered', clearDescription)
	unequip_button.connect('mouse_entered', clearDescription)
	select_charms.add_child(unequip_button)
	unequip_button.grab_focus()
	for charm in InventoryGlobals.INVENTORY.filter(func(item): return item is ResCharm):
		var button = OverworldGlobals.createItemButton(charm)
		button.pressed.connect(
			func():
			if slot_button == charm_slot_a:
				equipCharmOnCombatant(charm, 0, charm_slot_a)
			elif slot_button == charm_slot_b:
				equipCharmOnCombatant(charm, 1, charm_slot_b)
			elif slot_button == charm_slot_c:
				equipCharmOnCombatant(charm, 2, charm_slot_c)
			select_charms_panel.hide()
			charm_info_panel.hide()
			setFocusMode(equipped_charms, true)
			setFocusMode(member_container, true)
			if slot_button == charm_slot_a:
				charm_slot_a.grab_focus()
			elif slot_button == charm_slot_b:
				charm_slot_b.grab_focus()
			elif slot_button == charm_slot_c:
				charm_slot_c.grab_focus()
		)
		button.focus_entered.connect(
			func():
				updateItemDescription(charm)
		)
		button.mouse_entered.connect(
			func():
				updateItemDescription(charm)
		)
		select_charms.add_child(button)

func showWeaponEquipMenu():
	setFocusMode(equipped_charms, false)
	setFocusMode(member_container, false)
	clearButtons()
	select_charms_panel.show()
	var unequip_button = OverworldGlobals.createCustomButton()
	unequip_button.theme = preload("res://design/ItemButtons.tres")
	unequip_button.icon = preload('res://images/sprites/icon_cross.png')
	unequip_button.focused_entered_sound = preload("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	unequip_button.click_sound = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")
	unequip_button.pressed.connect(
		func():
			selected_combatant.unequipWeapon()
			weapon_button.icon = null
			weapon_button.text = 'Unarmed'
			select_charms_panel.hide()
			charm_info_panel.hide()
			setFocusMode(equipped_charms, true)
			setFocusMode(member_container, true)
			weapon_button.grab_focus()
	)
	unequip_button.connect('focus_entered', clearDescription)
	unequip_button.connect('mouse_entered', clearDescription)
	select_charms.add_child(unequip_button)
	unequip_button.grab_focus()
	for weapon in InventoryGlobals.INVENTORY.filter(func(item): return item is ResWeapon):
		var button = OverworldGlobals.createItemButton(weapon)
		button.pressed.connect(
			func():
			if weapon.canUse(selected_combatant):
				selected_combatant.equipWeapon(weapon)
				weapon_button.text = weapon.NAME
				weapon_button.icon = weapon.ICON
			select_charms_panel.hide()
			charm_info_panel.hide()
			setFocusMode(equipped_charms, true)
			setFocusMode(member_container, true)
			weapon_button.grab_focus()
		)
		button.mouse_entered.connect(
			func():
				updateItemDescription(weapon)
		)
		button.focus_entered.connect(
			func():
				updateItemDescription(weapon)
		)
		if !weapon.canUse(selected_combatant): button.disabled = true
		select_charms.add_child(button)

func _on_weapon_pressed():
	showWeaponEquipMenu()

func _on_slot_a_pressed():
	if selected_combatant.CHARMS[0] != null: 
		selected_combatant.unequipCharm(0)
		charm_slot_a.icon = preload("res://images/sprites/icon_plus.png")
	showCharmEquipMenu(charm_slot_a)

func _on_slot_b_pressed():
	if selected_combatant.CHARMS[1] != null: 
		selected_combatant.unequipCharm(1)
		charm_slot_b.icon = preload("res://images/sprites/icon_plus.png")
	showCharmEquipMenu(charm_slot_b)

func _on_slot_c_pressed():
	if selected_combatant.CHARMS[2] != null: 
		selected_combatant.unequipCharm(2)
		charm_slot_c.icon = preload("res://images/sprites/icon_plus.png")
	showCharmEquipMenu(charm_slot_c)

func updateEquipped():
	if selected_combatant.EQUIPPED_WEAPON != null:
		weapon_button.text = selected_combatant.EQUIPPED_WEAPON.NAME
		weapon_button.icon = selected_combatant.EQUIPPED_WEAPON.ICON
	else:
		weapon_button.icon = null
		weapon_button.text = 'Unarmed'
	
	charm_slot_a.icon = preload("res://images/sprites/icon_plus.png")
	charm_slot_b.icon = preload("res://images/sprites/icon_plus.png")
	charm_slot_c.icon = preload("res://images/sprites/icon_plus.png")
	if selected_combatant.CHARMS[0] != null:
		charm_slot_a.icon = selected_combatant.CHARMS[0].ICON
	if selected_combatant.CHARMS[1] != null:
		charm_slot_b.icon = selected_combatant.CHARMS[1].ICON
	if selected_combatant.CHARMS[2] != null:
		charm_slot_c.icon = selected_combatant.CHARMS[2].ICON

func equipCharmOnCombatant(charm: ResCharm, slot: int, slot_button):
	selected_combatant.equipCharm(charm, slot)
	if selected_combatant.CHARMS[slot] != null:
		slot_button.icon = charm.ICON

func updateItemDescription(item: ResItem):
	if item == null:
		return
	
	charm_info_panel.show()
	charm_description_general.text = item.getGeneralInfo()
	charm_description.text = item.getInformation()

func clearDescription():
	charm_description_general.text = ''
	charm_description.text = ''

func _on_weapon_mouse_entered():
	if selected_combatant.EQUIPPED_WEAPON != null:
		updateItemDescription(selected_combatant.EQUIPPED_WEAPON)
	else:
		charm_info_panel.hide()

func _on_slot_a_mouse_entered():
	if selected_combatant.CHARMS[0] != null:
		updateItemDescription(selected_combatant.CHARMS[0])
	else:
		charm_info_panel.hide()

func _on_slot_b_mouse_entered():
	if selected_combatant.CHARMS[1] != null:
		updateItemDescription(selected_combatant.CHARMS[1])
	else:
		charm_info_panel.hide()

func _on_slot_c_mouse_entered():
	if selected_combatant.CHARMS[2] != null:
		updateItemDescription(selected_combatant.CHARMS[2])
	else:
		charm_info_panel.hide()

func hideItemDescription():
	charm_info_panel.hide()

func _on_tab_container_tab_changed(tab):
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
		0: OverworldGlobals.setMenuFocus(pool)
		1: 
			OverworldGlobals.setMenuFocus(equipped_charms)
			if !selected_combatant.hasEquippedWeapon():
				weapon_button.icon = null
				weapon_button.text = 'Unarmed'
		2: attrib_adjust.focus()

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and (tabs.current_tab + 1 < tabs.get_tab_count() and !tabs.is_tab_disabled(tabs.current_tab + 1)):
		tabs.current_tab += 1
	elif Input.is_action_just_pressed('ui_tab_left') and (tabs.current_tab - 1 >= 0 and !tabs.is_tab_disabled(tabs.current_tab - 1)):
		tabs.current_tab -= 1

func setFocusMode(container, mode):
	for child in container.get_children():
		if child is Button:
			if mode:
				child.focus_mode = Control.FOCUS_ALL
			else:
				child.focus_mode = Control.FOCUS_NONE

func _on_change_formation_pressed():
	changing_formation = !changing_formation
	for member in getOtherMemberScenes():
		member.modulate = Color(Color.WHITE, 1.0)
	
	if changing_formation:
		tabs.hide()
		attrib_view.hide()
		member_name.hide()
		selected_combatant = null
		formation_button.text = 'Finish'
	else:
		tabs.show()
		attrib_view.show()
		member_name.show()
		formation_button.text = 'Change Formation'
		loadMembers()
