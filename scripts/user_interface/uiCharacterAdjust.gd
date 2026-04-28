extends Control
class_name MemberAdjustUI

const EQUIP_MENU = preload("res://scenes/user_interface/MiniInventory.tscn")
const SWORD_ICON = "res://images/sprites/icon_combat_item.png"
const SACK_ICON = "res://images/sprites/icon_charm.png"

@export var show_current_party = true
@onready var pool = $Abilities/MarginContainer/ScrollContainer/VBoxContainer
@onready var member_container = $Formation/Members/HBoxContainer
@onready var equipped_charms = $Character/StatAdjusters
@onready var weapon_button = $Character/StatAdjusters/Weapon
@onready var charm_slot_a = $Character/StatAdjusters/SlotA
@onready var charm_slot_b = $Character/StatAdjusters/SlotB
@onready var charm_slot_c = $Character/StatAdjusters/SlotC
@onready var equipment_select_point = $SubmenuPoint
@onready var formation_button = $Formation/ChangeFormation
@onready var character_view = $Character/Panel/Marker2D
@onready var character_name = $Character/Panel/Label
@onready var weapon_durability = $Character/StatAdjusters/Weapon/Label
@onready var talent_menu = $TalentControl/Talents
@onready var attrib_view = $Stats/HSplitContainer/AttributeView
@onready var stat_point_count = $TalentControl/ToggleView/StatPointCount
var selected_combatant: ResPlayerCombatant
var changing_formation: bool = false
var talent_menu_out:bool=false

#func addStatusEffectIcons():
#	for child in infliction.get_children():
#		child.queue_free()
#	for effect in selected_combatant.lingering_effects:
#		infliction.add_child(OverworldGlobals.createStatusEffectIcon(effect))

func _ready():
	loadMembers()
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		loadMemberInfo(OverworldGlobals.getCombatantSquad('Player')[0])
	member_container.visible = show_current_party
	formation_button.visible = show_current_party
	talent_menu.talent_interacted.connect(
		func():
			#addStatusEffectIcons()
			#updateTemperments()
			$Stats/HSplitContainer/TraitContainer.updateTraits(selected_combatant)
			updateStatPointCount()
	)

func loadMembers(set_focus:bool=true, preview_member:bool=false):
	for child in member_container.get_children():
		child.queue_free()
	
	for i in range(OverworldGlobals.getCombatantSquad('Player').size(), 0, -1):
		var member = OverworldGlobals.getCombatantSquad('Player')[i-1]
		var member_button = createMemberButton(member, preview_member)
		member_container.add_child(member_button)
		if i == 1 and set_focus:
			member_button.grab_focus()
			selected_combatant = member
			loadMemberInfo(selected_combatant)

func loadMemberInfo(member: ResCombatant, button: Button=null):
	character_name.text = member.name.to_upper()
	updateCharacterView(member)
	member.applyAbilityMutations()
	if talent_menu_out:
		_on_toggle_view_pressed()
	if changing_formation and selected_combatant == null:
		selected_combatant = member
		button.add_theme_color_override('font_color', Color.YELLOW)
		button.add_theme_color_override('border_color', Color.YELLOW)
	elif changing_formation and selected_combatant != null:
		swapMembers(selected_combatant, member)
		loadMembers(false, true)
		await get_tree().process_frame
		for child in member_container.get_children():
			if child.text == selected_combatant.name: 
				child.grab_focus()
				break
		selected_combatant = null
	else:
		selected_combatant = member
		loadAbilities()
		#updateTemperments()
		$Stats/HSplitContainer/TraitContainer.updateTraits(selected_combatant)
		#addStatusEffectIcons()
		updateEquipped()
	if selected_combatant != null:
		if selected_combatant.ability_set.size() >= PlayerGlobals.ability_cap:
			dimInactiveAbilities()
		updateStatPointCount()

	talent_menu.loadTalents(selected_combatant)
	attrib_view.combatant = selected_combatant
	if has_node('Roster'):
		get_node('Roster').inspect_mark.hide()

func updateCharacterView(member: ResPlayerCombatant):
	if character_view.has_node('CharacterBody2D'):
		var last_member = character_view.get_node('CharacterBody2D')
		character_view.remove_child(last_member)
		last_member.queue_free()
	
	#member.initializeCombatant()
	var character_scene = member.getScenePreview()
	if character_scene:
		character_scene.scale = Vector2(2,2)
		character_view.add_child(character_scene)
		character_scene.collision.disabled = true
		character_scene.combatant_resource.getAnimator().play('RESET')
		await character_scene.combatant_resource.getAnimator().animation_finished
		character_scene.playIdle()

func swapMembers(member_a: ResCombatant, member_b: ResCombatant):
	var team = OverworldGlobals.getCombatantSquad('Player')
	var member_a_pos = team.find(member_a)
	team[team.find(member_b)] = member_a
	team[member_a_pos] = member_b

func loadAbilities():
	clearChildren(pool)
	if selected_combatant.ability_pool.is_empty():
		return
	
	for ability in selected_combatant.ability_pool:
		if ability == null:
			selected_combatant.ability_pool.erase(ability)
			continue
		if PlayerGlobals.team_level < ability.required_level:
			continue
		createAbilityButton(ability, pool)
	
#	for i in range(32):
#		createAbilityButton(load("res://resources/combat/abilities/BasicAttack.tres"), pool)

func clearChildren(parent):
	for child in parent.get_children():
		if child.name.to_lower().contains('exclude'):
			continue
		parent.remove_child(child)
		child.queue_free()

func createAbilityButton(ability, location):
	var button: CustomButton = OverworldGlobals.createAbilityButton(ability)
	var has_unlocked = PlayerGlobals.hasUnlockedAbility(selected_combatant, ability) or ability.required_level == 0
	button.focused_entered_sound = load("res://audio/sounds/421354__jaszunio15__click_31.ogg")
	button.click_sound = load("res://audio/sounds/421304__jaszunio15__click_229.ogg")
	if selected_combatant.ability_set.has(ability):
		button.add_theme_icon_override('icon', load("res://images/sprites/ability_mark.png"))
	if !has_unlocked:
		button.add_theme_icon_override('icon', load("res://images/sprites/lock.png"))
		button.tooltip_text = str(ability.getCost())
	
	button.pressed.connect(
		func():
			if !has_unlocked:
				if button.has_focus() and PlayerGlobals.currency >= ability.getCost() and !PlayerGlobals.hasUnlockedAbility(selected_combatant, ability):
					PlayerGlobals.currency -= ability.getCost()
					PlayerGlobals.unlockAbility(selected_combatant, ability)
					OverworldGlobals.playSound('res://audio/sounds/721774__maodin204__cash-register.ogg')
					loadMemberInfo(selected_combatant)
			else:
				PlayerGlobals.setAbilityActive(selected_combatant, ability, !selected_combatant.ability_set.has(ability))
			
			if selected_combatant.ability_set.has(ability):
				button.add_theme_icon_override('icon', load("res://images/sprites/ability_mark.png"))
			else:
				button.remove_theme_icon_override('icon')
			
			if selected_combatant.ability_set.size() >= PlayerGlobals.ability_cap:
				dimInactiveAbilities()
			elif selected_combatant.ability_set.size() < PlayerGlobals.ability_cap:
				undimAbilities()
	)
	location.add_child(button)

func dimInactiveAbilities():
	for ability_button in pool.get_children():
		ability_button.setDisabled(!selected_combatant.ability_set.has(ability_button.ability))

func undimAbilities():
	for ability_button in pool.get_children():
		ability_button.setDisabled(false)
		#ability_button.disabled = false
		#ability_button.undimButton()

func setButtonDisabled(set_to: bool):
	for button in pool.get_children():
		button.setDisabled(set_to)
		if selected_combatant.ability_set.size() >= PlayerGlobals.ability_cap and !set_to:
			button.setDisabled(!selected_combatant.ability_set.has(button.ability))
	
	for button in equipped_charms.get_children():
		button.setDisabled(set_to)

func createMemberButton(member: ResCombatant, preview_combatant:bool=false):
	var button = OverworldGlobals.createCustomButton(load("res://design/PartyButtons.tres"))
	button.alignment =HORIZONTAL_ALIGNMENT_RIGHT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD
	button.custom_minimum_size.x = 64
	button.text = member.name
	button.pressed.connect(func(): loadMemberInfo(member, button))
	if preview_combatant:
		var character_scene = member.getScenePreview()
		button.add_child(member.combatant_scene)
		if character_scene.collision != null:
			character_scene.collision.disabled = true
		
	return button

func getOtherMemberScenes(except_name: String=''):
	var out = []
	for body in member_container.get_children():
		if body.text == except_name and except_name != '': continue
		out.append(body.get_node('CharacterBody2D'))
	return out

func _on_weapon_pressed():
	OverworldGlobals.showMiniMenu(
		EQUIP_MENU,
		weapon_button,
		0,
		func(item): 
			selected_combatant.equipWeapon(item)
			updateEquipped(),
		func(item): return item is ResWeapon and item.canUse(selected_combatant)
		)

func _on_slot_a_pressed():
	OverworldGlobals.showMiniMenu(
		EQUIP_MENU,
		charm_slot_a,
		0,
		func(item): 
			selected_combatant.equipCharm(item,0)
			updateEquipped(),
		func(item): return item is ResCharm and !selected_combatant.hasCharm(item)
		)

func _on_slot_b_pressed():
	OverworldGlobals.showMiniMenu(
		EQUIP_MENU,
		charm_slot_b,
		0,
		func(item): 
			selected_combatant.equipCharm(item,1)
			updateEquipped(),
		func(item): return item is ResCharm and !selected_combatant.hasCharm(item)
		)

func _on_slot_c_pressed():
	OverworldGlobals.showMiniMenu(
		EQUIP_MENU,
		charm_slot_c,
		0,
		func(item): 
			selected_combatant.equipCharm(item,2)
			updateEquipped(),
		func(item): return item is ResCharm and !selected_combatant.hasCharm(item)
		)

func showEquipment(type:int, slot:int, unequip_button_function: Callable=func():pass):
	OverworldGlobals.showMiniMenu(
		EQUIP_MENU,
		weapon_button,
		0,
		func(item): 
			selected_combatant.equipWeapon(item)
			updateEquipped(),
		func(item): return item is ResWeapon
		)

func updateEquipped():
	if selected_combatant == null:
		return
	
	if selected_combatant.equipped_weapon != null:
		#weapon_button.text = selected_combatant.equipped_weapon.name
		weapon_button.icon = selected_combatant.equipped_weapon.icon
		weapon_durability.text = '%s / %s' % [selected_combatant.equipped_weapon.durability, selected_combatant.equipped_weapon.max_durability]
		if selected_combatant.equipped_weapon.durability <= 0:
			weapon_durability.modulate = Color.RED
		weapon_durability.show()
	else:
		weapon_button.icon = load(SWORD_ICON)
		#weapon_button.text = 'NO  GEAR'
		weapon_durability.modulate = Color.WHITE
		weapon_durability.hide()
	
	charm_slot_a.icon = load(SACK_ICON)
	charm_slot_b.icon = load(SACK_ICON)
	charm_slot_c.icon = load(SACK_ICON)
	if selected_combatant.charms[0] != null:
		charm_slot_a.icon = selected_combatant.charms[0].icon
	if selected_combatant.charms[1] != null:
		charm_slot_b.icon = selected_combatant.charms[1].icon
	if selected_combatant.charms[2] != null:
		charm_slot_c.icon = selected_combatant.charms[2].icon

func equipCharmOnCombatant(charm: ResCharm, slot: int, slot_button):
	selected_combatant.equipCharm(charm, slot)
	if selected_combatant.charms[slot] != null:
		slot_button.icon = charm.icon

func _on_change_formation_pressed():
	if equipment_select_point.has_node('CharacterEquip'):
		equipment_select_point.get_node('CharacterEquip').equipped_item.emit()
		equipment_select_point.get_node('CharacterEquip').queue_free()
	changing_formation = !changing_formation
	
	if changing_formation:
		showCombatantsOnButtons()
		setButtonDisabled(true)
		selected_combatant = null
		formation_button.icon = load("res://images/sprites/icon_done.png")
		formation_button.tooltip_text = 'Done?'
	else:
		setButtonDisabled(false)
		loadMembers()
		formation_button.icon = load("res://images/sprites/icon_rotating_arrows.png")
		formation_button.tooltip_text = 'Change formation.'

func showCombatantsOnButtons():
	for child in member_container.get_children():
		var combatant = OverworldGlobals.getCombatant('Player', child.text)
		combatant.initializeCombatant()
		child.add_child(combatant.combatant_scene)

func grabFocus():
	OverworldGlobals.setMenuFocus(pool)

func _on_toggle_view_pressed():
	var offset = talent_menu.size.x-50
	var modulate_tween = create_tween()
	var pos_tween = create_tween()
	if !talent_menu_out:
		talent_menu.show()
		OverworldGlobals.setControlFocus(talent_menu.getContainer('BaseTalents', 'talents'))
		pos_tween.tween_property(talent_menu, 'position', talent_menu.position+Vector2(offset,0),0.25).set_trans(Tween.TRANS_CUBIC)
		modulate_tween.tween_property(talent_menu,'modulate',Color.WHITE,0.2)
		talent_menu_out = true
		setButtonDisabled(true)
		stat_point_count.hide()
	else:
		pos_tween.tween_property(talent_menu, 'position', talent_menu.position-Vector2(offset,0),0.25).set_trans(Tween.TRANS_CUBIC)
		modulate_tween.tween_property(talent_menu,'modulate',Color.TRANSPARENT,0.2)
		talent_menu_out = false
		setButtonDisabled(false)
		stat_point_count.show()
		await modulate_tween.finished
		talent_menu.hide()

func updateStatPointCount():
	if selected_combatant.stat_points > 0:
		stat_point_count.self_modulate = Color.WHITE
	else:
		stat_point_count.self_modulate = Color.TRANSPARENT
	
	stat_point_count.text = str(selected_combatant.stat_points)
	
