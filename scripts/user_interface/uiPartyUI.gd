extends Control

@onready var tabs = $TabContainer
@onready var description = $Description/DescriptionLabel
@onready var stat_panel = $TabContainer/Attributes/Attributes
@onready var ability_pool_panel = $TabContainer/Abilities/VBoxContainer
@onready var equipment_panel = $TabContainer/Equipment/VBoxContainer
@onready var status_panel = $"TabContainer/Status Effects/VBoxContainer"
var subject_combatant: ResPlayerCombatant

func loadInformation():
	clearInformation()
	stat_panel.combatant = subject_combatant
	description.text = subject_combatant.description
	
	for ability in subject_combatant.ability_pool:
		if ability == null: continue
		var ability_button = OverworldGlobals.createCustomButton()
		ability_button.text = ability.name
		ability_button.mouse_entered.connect(
			func updateDesciption():
				description.text = ability.getRichDescription()
		)
		ability_button.focus_entered.connect(
			func updateDesciption():
				description.text = ability.getRichDescription()
		)
		ability_pool_panel.add_child(ability_button)
	
	if subject_combatant.equipped_weapon != null:
		var weapon_button = OverworldGlobals.createCustomButton()
		weapon_button.text = subject_combatant.equipped_weapon.name
		weapon_button.mouse_entered.connect(
		func updateDesciption():
			description.text = subject_combatant.equipped_weapon.getInformation()
		)
		weapon_button.focus_entered.connect(
		func updateDesciption():
			description.text = subject_combatant.equipped_weapon.getInformation()
		)
		equipment_panel.add_child(weapon_button)
	
	for charm in subject_combatant.charms.values():
		if charm == null:
			continue
		
		var equipment_button = OverworldGlobals.createCustomButton()
		equipment_button.text = charm.name
		equipment_button.mouse_entered.connect(
		func updateDesciption():
			description.text = charm.getInformation()
		)
		equipment_button.focus_entered.connect(
		func updateDesciption():
			description.text = charm.getInformation()
		)
		equipment_panel.add_child(equipment_button)
	
	
	for effect_name in subject_combatant.lingering_effects:
		var status_button = OverworldGlobals.createCustomButton()
		status_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		status_button.text = effect_name
		status_button.mouse_entered.connect(
		func updateDesciption():
			var effect = CombatGlobals.loadStatusEffect(effect_name)
			description.text = "\n[img]%s[/img] %s\n" % [effect.texture.resource_path, effect.description]
		)
		status_button.focus_entered.connect(
		func updateDesciption():
			var effect = CombatGlobals.loadStatusEffect(effect_name)
			description.text = "\n[img]%s[/img] %s\n" % [effect.texture.resource_path, effect.description]
		)
		status_panel.add_child(status_button)
	
	stat_panel.combatant = subject_combatant

func clearInformation():
	description.text = ''
	
	for child in ability_pool_panel.get_children():
		ability_pool_panel.remove_child(child)
		child.queue_free()
	
	for child in equipment_panel.get_children():
		equipment_panel.remove_child(child)
		child.queue_free()
	
	for child in status_panel.get_children():
		status_panel.remove_child(child)
		child.queue_free()

func _on_tab_container_tab_changed(tab):
	description.text = ''
	match tab:
		1: OverworldGlobals.setMenuFocus(ability_pool_panel)
		2: OverworldGlobals.setMenuFocus(equipment_panel)
		3: OverworldGlobals.setMenuFocus(status_panel)

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and tabs.current_tab + 1 < tabs.get_tab_count():
		tabs.current_tab += 1
	elif Input.is_action_just_pressed('ui_tab_left') and tabs.current_tab - 1 >= 0:
		tabs.current_tab -= 1
