# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var description = $Description/DescriptionLabel
@onready var stat_panel = $TabContainer/Attributes/Attributes
@onready var ability_pool_panel = $TabContainer/Abilities/VBoxContainer
@onready var equipment_panel = $TabContainer/Equipment/VBoxContainer
@onready var status_panel = $"TabContainer/Status Effects/VBoxContainer"
var subject_combatant: ResPlayerCombatant

func loadInformation():
	clearInformation()
	stat_panel.combatant = subject_combatant
	description.text = subject_combatant.DESCRIPTION
	
	for ability in subject_combatant.ABILITY_POOL:
		if ability == null: continue
		var ability_button = OverworldGlobals.createCustomButton()
		ability_button.text = ability.NAME
		ability_button.mouse_entered.connect(
			func updateDesciption():
				description.text = ability.getRichDescription()
		)
		ability_pool_panel.add_child(ability_button)
	
	for charm in subject_combatant.CHARMS.values():
		if charm == null:
			continue
		
		var equipment_button = OverworldGlobals.createCustomButton()
		equipment_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		equipment_button.text = charm.NAME
		equipment_button.mouse_entered.connect(
		func updateDesciption():
			description.text = charm.getInformation()
		)
		equipment_panel.add_child(equipment_button)
	
	for effect_name in subject_combatant.LINGERING_STATUS_EFFECTS:
		var status_button = OverworldGlobals.createCustomButton()
		status_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		status_button.text = effect_name
		status_button.mouse_entered.connect(
		func updateDesciption():
			var effect = CombatGlobals.loadStatusEffect(effect_name)
			description.text = "\n[img]%s[/img] %s\n" % [effect.TEXTURE.resource_path, effect.DESCRIPTION]
		)
		status_panel.add_child(status_button)
	
	stat_panel.combatant = subject_combatant

func clearInformation():
	description.text = ''
	
	for child in ability_pool_panel.get_children():
		child.queue_free()
	
	for child in equipment_panel.get_children():
		child.queue_free()
	
	for child in status_panel.get_children():
		child.queue_free()


func _on_tab_container_tab_changed(_tab):
	description.text = ''
