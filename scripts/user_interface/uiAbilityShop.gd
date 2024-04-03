extends Control

@onready var pool = $TabContainer/Abilities/Pool/Scroll/VBoxContainer
@onready var abilities = $TabContainer/Abilities/Abilities/Scroll/VBoxContainer
@onready var description = $TabContainer/Abilities/DescriptionPanel/Label
@onready var member_container = $Members/HBoxContainer
@onready var attrib_adjust = $TabContainer/Attributes
@onready var attrib_view = $AttributeView
@onready var equipped_charms = $TabContainer/Charms/EquippedCharms
@onready var select_charms = $TabContainer/Charms/Panel/SelectCharms/VBoxContainer
@onready var select_charms_panel = $TabContainer/Charms/Panel
@onready var charm_description = $TabContainer/Charms/Description
@onready var charm_slot_a = $TabContainer/Charms/EquippedCharms/SlotA
@onready var charm_slot_b = $TabContainer/Charms/EquippedCharms/SlotB
@onready var charm_slot_c = $TabContainer/Charms/EquippedCharms/SlotC

var selected_combatant: ResPlayerCombatant

func _process(_delta):
	if selected_combatant != null:
		attrib_view.combatant = selected_combatant
		attrib_adjust.combatant = selected_combatant

func _ready():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var member_button = Button.new()
		member_button.text = member.NAME
		member_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		member_button.custom_minimum_size.x = 96
		member_button.pressed.connect(
			func loadMemberInformation():
				selected_combatant = member
				select_charms_panel.hide()
				loadAbilities()
				updateEquipped()
		)
		member_container.add_child(member_button)

func loadAbilities():
	clearButtons()
	if selected_combatant.ABILITY_POOL.is_empty():
		return
	
	print(selected_combatant.ABILITY_POOL)
	for ability in selected_combatant.ABILITY_POOL:
		if ability == null: 
			selected_combatant.ABILITY_POOL.erase(ability)
			continue
		if PlayerGlobals.PARTY_LEVEL < ability.REQUIRED_LEVEL: 
			continue
		createButton(ability, pool)
	for ability in selected_combatant.ABILITY_SET:
		createButton(ability, abilities)

func loadCharms():
	clearButtons()
	pass

func clearButtons():
	for child in abilities.get_children():
		child.queue_free()
	for chid in pool.get_children():
		chid.queue_free()
	#for child in equipped_charms.get_children():
	#	child.queue_free()
	for child in select_charms.get_children():
		child.queue_free()

func createButton(ability, location):
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = ability.NAME
	button.pressed.connect(
		func transferItem():
			if selected_combatant.ABILITY_POOL.has(ability):
				if selected_combatant.ABILITY_SET.size() + 1 > 4:
					return
				selected_combatant.ABILITY_POOL.erase(ability)
				selected_combatant.ABILITY_SET.append(ability)
				loadAbilities()
			elif selected_combatant.ABILITY_SET.has(ability):
				selected_combatant.ABILITY_SET.erase(ability)
				selected_combatant.ABILITY_POOL.append(ability)
				loadAbilities()
	)
	button.mouse_entered.connect(
		func updateInfo():
			description.text = '' 
			description.text = ability.DESCRIPTION
	)
	location.add_child(button)

func showCharmEquipMenu(slot_button: Button):
	clearButtons()
	select_charms_panel.show()
	var unequip_button = CustomButton.new()
	unequip_button.text = 'UNEQUIP'
	unequip_button.pressed.connect(
		func():
			if slot_button == charm_slot_a:
				selected_combatant.unequipCharm(0)
			elif slot_button == charm_slot_b:
				selected_combatant.unequipCharm(1)
			elif slot_button == charm_slot_c:
				selected_combatant.unequipCharm(2)
			slot_button.text = 'EMPTY'
			select_charms_panel.hide()
	)
	select_charms.add_child(unequip_button)
	for charm in InventoryGlobals.INVENTORY.filter(func(item): return item is ResCharm):
		var button = CustomButton.new()
		button.text = charm.NAME
		button.pressed.connect(
			func():
			if slot_button == charm_slot_a:
				equipCharmOnCombatant(charm, 0, charm_slot_a)
			elif slot_button == charm_slot_b:
				equipCharmOnCombatant(charm, 1, charm_slot_b)
			elif slot_button == charm_slot_c:
				equipCharmOnCombatant(charm, 2, charm_slot_c)
			select_charms_panel.hide()
		)
		select_charms.add_child(button)

func _on_slot_a_pressed():
	showCharmEquipMenu(charm_slot_a)

func _on_slot_b_pressed():
	showCharmEquipMenu(charm_slot_b)

func _on_slot_c_pressed():
	showCharmEquipMenu(charm_slot_c)

func updateEquipped():
	charm_slot_a.text = 'EMPTY'
	charm_slot_b.text = 'EMPTY'
	charm_slot_c.text = 'EMPTY'
	
	if selected_combatant.CHARMS[0] != null:
		charm_slot_a.text = selected_combatant.CHARMS[0].NAME
	if selected_combatant.CHARMS[1] != null:
		charm_slot_b.text = selected_combatant.CHARMS[1].NAME
	if selected_combatant.CHARMS[2] != null:
		charm_slot_c.text = selected_combatant.CHARMS[2].NAME

func equipCharmOnCombatant(charm: ResCharm, slot: int, slot_button):
	selected_combatant.equipCharm(charm, slot)
	if selected_combatant.CHARMS[slot] != null:
		slot_button.text = charm.NAME

func _on_tab_container_tab_button_pressed(tab):
	pass
