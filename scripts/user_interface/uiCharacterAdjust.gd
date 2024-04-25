extends Control

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
@onready var charm_slot_a = $TabContainer/Charms/EquippedCharms/SlotA
@onready var charm_slot_b = $TabContainer/Charms/EquippedCharms/SlotB
@onready var charm_slot_c = $TabContainer/Charms/EquippedCharms/SlotC
@onready var member_preview = $Marker2D
@onready var member_name = $Label
var selected_combatant: ResPlayerCombatant

func _process(_delta):
	if selected_combatant != null:
		attrib_view.combatant = selected_combatant
		attrib_adjust.combatant = selected_combatant

func _ready():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var member_button = OverworldGlobals.createCustomButton()
		member_button.text = member.NAME
		member_button.pressed.connect(
			func(): loadMemberInfo(member)
		)
		member_container.add_child(member_button)
	
	loadMemberInfo(OverworldGlobals.getCombatantSquad('Player')[0])

func loadMemberInfo(member: ResCombatant):
	for child in member_preview.get_children():
		child.queue_free()
	member.initializeCombatant()
	member_preview.add_child(member.SCENE)
	member.getAnimator().play('Idle')
	selected_combatant = member
	select_charms_panel.hide()
	member_name.text = member.NAME
	loadAbilities()
	updateEquipped()

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

func loadCharms():
	clearButtons()
	pass

func clearButtons():
	for chid in pool.get_children():
		chid.queue_free()
	for child in select_charms.get_children():
		child.queue_free()

func createButton(ability, location):
	var button = OverworldGlobals.createCustomButton()
	button.text = ability.NAME
	if selected_combatant.ABILITY_SET.has(ability):
		button.add_theme_icon_override('icon', preload("res://images/sprites/circle_filled.png"))
	
	button.pressed.connect(
		func():
			if !selected_combatant.ABILITY_SET.has(ability):
				if selected_combatant.ABILITY_SET.size() >= 4:
					OverworldGlobals.showPlayerPrompt('Max abilities enabled.')
					return
				selected_combatant.ABILITY_SET.append(ability)
				button.add_theme_icon_override('icon', preload("res://images/sprites/circle_filled.png"))
			elif selected_combatant.ABILITY_SET.has(ability):
				selected_combatant.ABILITY_SET.erase(ability)
				button.remove_theme_icon_override('icon')
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.getRichDescription()
	)
	button.mouse_exited.connect(
		func():
			description.text = '' 
	)
	location.add_child(button)

func showCharmEquipMenu(slot_button: Button):
	clearButtons()
	select_charms_panel.show()
	var unequip_button = OverworldGlobals.createCustomButton()
	unequip_button.theme = preload("res://design/ItemButtons.tres")
	unequip_button.icon = preload('res://images/sprites/icon_cross.png')
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
	)
	select_charms.add_child(unequip_button)
	for charm in InventoryGlobals.INVENTORY.filter(func(item): return item is ResCharm):
		var button = OverworldGlobals.createCustomButton()
		button.theme = preload("res://design/ItemButtons.tres")
		button.icon = charm.ICON
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
		)
		select_charms.add_child(button)
		button.mouse_entered.connect(
			func():
				updateItemDescription(charm)
		)

func _on_slot_a_pressed():
	showCharmEquipMenu(charm_slot_a)

func _on_slot_b_pressed():
	showCharmEquipMenu(charm_slot_b)

func _on_slot_c_pressed():
	showCharmEquipMenu(charm_slot_c)

func updateEquipped():
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

func _on_slot_a_mouse_entered():
	updateItemDescription(selected_combatant.CHARMS[0])

func _on_slot_b_mouse_entered():
	updateItemDescription(selected_combatant.CHARMS[1])

func _on_slot_c_mouse_entered():
	updateItemDescription(selected_combatant.CHARMS[2])

func hideItemDescription():
	charm_info_panel.hide()


func _on_tab_container_tab_changed(tab):
	if tab == 0:
		loadAbilities()
		attrib_view.hide()
	elif tab == 1 or tab == 2:
		attrib_view.show()
