# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var description = $Description/DescriptionLabel
@onready var stat_panel = $TabContainer/Attributes/Attributes
@onready var ability_panel = $TabContainer/Abilities/VBoxContainer
@onready var ability_pool_panel = $"TabContainer/Ability Pool/VBoxContainer"
@onready var equipment_panel = $TabContainer/Equipment/VBoxContainer
@onready var status_panel = $"TabContainer/Status Effects/VBoxContainer"

var subject_combatant: ResPlayerCombatant

func loadInformation():
	clearInformation()
	stat_panel.combatant = subject_combatant
	description.text = subject_combatant.DESCRIPTION
	
	for ability in subject_combatant.ABILITY_SET:
		var ability_button = Button.new()
		ability_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ability_button.text = ability.NAME
		ability_button.mouse_entered.connect(
			func updateDesciption():
				description.text = ability.DESCRIPTION
		)
		ability_panel.add_child(ability_button)
	
	for ability in subject_combatant.ABILITY_POOL:
		var ability_button = Button.new()
		ability_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ability_button.text = ability.NAME
		ability_button.mouse_entered.connect(
			func updateDesciption():
				description.text = ability.DESCRIPTION
		)
		ability_pool_panel.add_child(ability_button)
	
	for charm in subject_combatant.CHARMS:
		if charm == null:
			continue
		
		var equipment_button = Button.new()
		equipment_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		equipment_button.text = charm.NAME
		equipment_button.mouse_entered.connect(
		func updateDesciption():
			description.text = charm.getInformation()
		)
		equipment_panel.add_child(equipment_button)
	
	for effect_name in subject_combatant.LINGERING_STATUS_EFFECTS:
		var status_button = Button.new()
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
	#stat_panel.text = ''
	
	for child in ability_panel.get_children():
		child.queue_free()
	
	for child in ability_pool_panel.get_children():
		child.queue_free()
	
	for child in equipment_panel.get_children():
		child.queue_free()
	
	for child in status_panel.get_children():
		child.queue_free()


func _on_tab_container_tab_changed(tab):
	description.text = ''
