extends Control
class_name MemberAdjustUI

const SWORD_ICON = "res://images/sprites/icon_weapon.png"
const SACK_ICON = "res://images/sprites/icon_sack.png"

@export var show_temperments = false
@onready var pool = $Abilities/MarginContainer/ScrollContainer/VBoxContainer
@onready var member_container = $Formation/Members/HBoxContainer
@onready var stat_points = $Character/Panel/Button/Label
@onready var show_attrib_adjust = $Character/Panel/Button
@onready var attrib_adjust = $Character/SubMenus/AttributeAdjust
@onready var attrib_view = $Stats/HSplitContainer/AttributeView
@onready var equipped_charms = $Character/StatAdjusters
@onready var weapon_button = $Character/StatAdjusters/Weapon
@onready var charm_slot_a = $Character/StatAdjusters/SlotA
@onready var charm_slot_b = $Character/StatAdjusters/SlotB
@onready var charm_slot_c = $Character/StatAdjusters/SlotC
@onready var equipment_select_point = $SubmenuPoint
@onready var formation_button = $Formation/ChangeFormation
@onready var infliction = $Character/Panel/Label/Infliction
@onready var temperments = $Stats/HSplitContainer/VFlowContainer
@onready var primary_temperments = $Stats/HSplitContainer/VFlowContainer/Temperment/Primary/PrimaryTemperment
@onready var secondary_temperments = $Stats/HSplitContainer/VFlowContainer/Temperment/Secondary/PrimaryTemperment
@onready var character_view = $Character/Panel/Marker2D
@onready var character_name = $Character/Panel/Label
@onready var weapon_durability = $Character/StatAdjusters/Weapon/Label
@onready var toggle_temperments = $Formation/ShowTemperments
var selected_combatant: ResPlayerCombatant
var changing_formation: bool = false

func _process(_delta):
	if selected_combatant != null:
		attrib_view.combatant = selected_combatant
		attrib_adjust.combatant = selected_combatant
		if selected_combatant.stat_points > 0:
			stat_points.text = str(selected_combatant.stat_points)
		else:
			stat_points.text = ''

func addStatusEffectIcons():
	for child in infliction.get_children():
		child.queue_free()
	for effect in selected_combatant.lingering_effects:
		infliction.add_child(OverworldGlobals.createStatusEffectIcon(effect))

func _ready():
	loadMembers()
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		loadMemberInfo(OverworldGlobals.getCombatantSquad('Player')[0])

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
		attrib_adjust.hide()
		loadAbilities()
		updateTemperments()
		updateEquipped()
	if selected_combatant != null:
		if selected_combatant.ability_set.size() >= 4:
			dimInactiveAbilities()
		if selected_combatant.isInflicted():
			addStatusEffectIcons()
	
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
		if !changing_formation:
			var cast_anim = ['Cast_Misc', 'Cast_Melee', 'Cast_Ranged'].pick_random()
			await character_scene.doAnimation(cast_anim)
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

func clearChildren(parent):
	for child in parent.get_children():
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
			
			if selected_combatant.ability_set.size() >= 4:
				dimInactiveAbilities()
			elif selected_combatant.ability_set.size() < 4:
				undimAbilities()
	)
	location.add_child(button)

func dimInactiveAbilities():
	for ability_button in pool.get_children():
		if !selected_combatant.ability_set.has(ability_button.ability):
			ability_button.disabled = true
			ability_button.dimButton()

func undimAbilities():
	for ability_button in pool.get_children():
		ability_button.disabled = false
		ability_button.undimButton()

func setButtonDisabled(set_to: bool):
	for button in pool.get_children():
		button.disabled = set_to
		button.dimButton()
	for button in equipped_charms.get_children():
		button.disabled = set_to
	show_attrib_adjust.disabled = set_to
	toggle_temperments.disabled = set_to

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
	await showEquipment(1, -1, 
	func(): 
		if selected_combatant.hasEquippedWeapon():
			selected_combatant.unequipWeapon()
		)
	updateEquipped()
	weapon_button.grab_focus()

func _on_slot_a_pressed():
	if selected_combatant.charms[0] != null: 
		selected_combatant.unequipCharm(0)
		charm_slot_a.icon = load(SACK_ICON)
	await showEquipment(0, 0)
	updateEquipped()
	charm_slot_a.grab_focus()

func _on_slot_b_pressed():
	if selected_combatant.charms[1] != null: 
		selected_combatant.unequipCharm(1)
		charm_slot_b.icon = load(SACK_ICON)
	await showEquipment(0, 1)
	updateEquipped()
	charm_slot_b.grab_focus()

func _on_slot_c_pressed():
	if selected_combatant.charms[2] != null: 
		selected_combatant.unequipCharm(2)
		charm_slot_c.icon = load(SACK_ICON)
	await showEquipment(0, 2)
	updateEquipped()
	charm_slot_c.grab_focus()

func showEquipment(type:int, slot:int, unequip_button_function: Callable=func():pass):
	var equipment: EquipmentInterface = load("res://scenes/user_interface/CharacterEquip.tscn").instantiate()
	equipment_select_point.add_child(equipment)
	equipment.z_index = 10
	equipment.showEquipment(type, selected_combatant, slot)
	equipment.unequip_button.pressed.connect(unequip_button_function)
	await equipment.equipped_item

func updateEquipped():
	await get_tree().process_frame
	if equipment_select_point.has_node('CharacterEquip'):
		equipment_select_point.get_node('CharacterEquip').equipped_item.emit()
		equipment_select_point.get_node('CharacterEquip').queue_free()
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
	attrib_adjust.hide()
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

func updateTemperments():
	clearChildren(primary_temperments)
	clearChildren(secondary_temperments)
	selected_combatant.applyTemperments(true)
	for temperment in selected_combatant.temperment['primary']:
		primary_temperments.add_child(createTempermentLabel(temperment, 'primary'))
	for temperment in selected_combatant.temperment['secondary']:
		secondary_temperments.add_child(createTempermentLabel(temperment, 'secondary'))
	if selected_combatant.hasEquippedWeapon() and !selected_combatant.equipped_weapon.canUse(selected_combatant):
		selected_combatant.unequipWeapon()

func createTempermentLabel(temperment: String, type: String):
	var stat_tag
	var bb='[center]'
	if type == 'primary':
		stat_tag = 'pt_'
	elif type == 'secondary':
		stat_tag = 'st_'
	var temperment_label = RichTextLabel.new()
	temperment_label.bbcode_enabled = true
	temperment_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	temperment_label.fit_content = true
	temperment_label.text = bb+temperment.capitalize()
	temperment_label.tooltip_text = formatModifiers(selected_combatant.stat_modifiers[stat_tag+temperment], false)
	return temperment_label

func formatModifiers(stat_dict: Dictionary, bb_code:bool=true) -> String:
	var result = ""
	for key in stat_dict.keys():
		var value = stat_dict[key]
		if value is float: 
			value *= 100.0
		if stat_dict[key] > 0 and stat_dict[key]:
			if bb_code: result += '[color=GREEN_YELLOW]'
			if value is float: 
				result += "+" + str(value) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(value) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			if bb_code: result += '[color=ORANGE_RED]'
			if value is float: 
				result += str(value) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(value) + " " +key.to_upper().replace('_', ' ') + "\n"
		if bb_code: result += '[/color]'
	return result


func _on_button_pressed():
	if attrib_adjust.visible:
		setButtonDisabled(false)
		attrib_adjust.hidePanel()
	else:
		setButtonDisabled(true)
		attrib_adjust.showPanel()
		attrib_adjust.focus()

func grabFocus():
	OverworldGlobals.setMenuFocus(pool)


func _on_show_temperments_pressed():
	if temperments.visible:
		temperments.hide()
		toggle_temperments.icon = load("res://images/sprites/icon_half_face.png")
		toggle_temperments.tooltip_text = 'Show Temperments'
	else:
		temperments.show()
		toggle_temperments.icon = load("res://images/sprites/icon_half_face_b.png")
		toggle_temperments.tooltip_text = 'Hide Temperments'
