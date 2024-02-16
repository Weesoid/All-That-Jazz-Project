# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var character_name = $Panel/CharacterName
@onready var description = $Description/DescriptionLabel
@onready var stat_panel = $TabContainer/Attributes
@onready var ability_panel = $TabContainer/Abilities/VBoxContainer
@onready var ability_pool_panel = $"TabContainer/Ability Pool/VBoxContainer"
@onready var equipment_panel = $TabContainer/Equipment/VBoxContainer
@onready var status_panel = $"TabContainer/Status Effects/VBoxContainer"

var subject_combatant: ResPlayerCombatant

func loadInformation():
	clearInformation()
	character_name.text = subject_combatant.NAME
	stat_panel.text = subject_combatant.getStringStats()
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
	
	for equipment in subject_combatant.EQUIPMENT.values():
		if equipment == null:
			continue
		
		var equipment_button = Button.new()
		equipment_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		equipment_button.text = getSlotName(equipment) + equipment.NAME
		equipment_button.mouse_entered.connect(
		func updateDesciption():
			description.text = equipment.getStringStats()
		)
		equipment_panel.add_child(equipment_button)
	
	for charm in subject_combatant.CHARMS:
		if charm == null:
			continue
		
		var equipment_button = Button.new()
		equipment_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		equipment_button.text = getSlotName(charm) + charm.NAME
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
	
	stat_panel.text = subject_combatant.getStringStats()

func clearInformation():
	character_name.text = ''
	description.text = ''
	stat_panel.text = ''
	
	for child in ability_panel.get_children():
		child.queue_free()
	
	for child in ability_pool_panel.get_children():
		child.queue_free()
	
	for child in equipment_panel.get_children():
		child.queue_free()
	
	for child in status_panel.get_children():
		child.queue_free()

func getSlotName(item):
	if item is ResArmor:
		return 'ARM '
	elif item is ResWeapon:
		return 'WPN '
	elif item is ResCharm:
		return 'CRM '
	else:
		return '??? '
