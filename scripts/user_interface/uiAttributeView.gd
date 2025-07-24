extends Control

@export var borders = true
@export var view_hidden = true
@export var view_abilities = false
@export var view_debug = false

@onready var combatant: ResCombatant
@onready var attribute_tab = $Attributes
@onready var hidden_tab = $HiddenAttributes
@onready var hp_val = $Attributes/MarginContainer/VBoxContainer/Health/ProgressBar
@onready var brawn_val = $Attributes/MarginContainer/VBoxContainer/Brawn/ProgressBar
@onready var grit_val = $Attributes/MarginContainer/VBoxContainer/Grit/ProgressBar
@onready var handling_val = $Attributes/MarginContainer/VBoxContainer/Handling/CustomCountBar
@onready var hustle_val = $Attributes/MarginContainer/VBoxContainer/Hustle/Value
@onready var acc_val = $HiddenAttributes/MarginContainer/VBoxContainer/Accuracy/ProgressBar
@onready var crit_d_val = $HiddenAttributes/MarginContainer/VBoxContainer/Dodge/Value
@onready var crit_val = $HiddenAttributes/MarginContainer/VBoxContainer/Crit/ProgressBar
@onready var resist_val = $HiddenAttributes/MarginContainer/VBoxContainer/Resist/ProgressBar
@onready var healm_val = $HiddenAttributes/MarginContainer/VBoxContainer/HealMult/Value
@onready var hp_text = $Attributes/MarginContainer/VBoxContainer/Health/ProgressBar/HealthValues
@onready var debug_status = $Debug
#@onready var temperments = $Temperments
#@onready var p_temp_name = $Temperments/MarginContainer/VBoxContainer/PrimaryTemperment/Label
#@onready var s_temp_name = $Temperments/MarginContainer/VBoxContainer/SecondaryTemperment/Label
#@onready var p_temp_val = $Temperments/MarginContainer/VBoxContainer/PrimaryTemperment/Values
#@onready var s_temp_val = $Temperments/MarginContainer/VBoxContainer/SecondaryTemperment/Values
@onready var abilities_label = $Abilities

func _ready():
	if !borders:
		var stylebox:StyleBox = preload("res://design/BorderlessContiner.tres")
		attribute_tab.add_theme_stylebox_override('panel', stylebox)
		hidden_tab.add_theme_stylebox_override('panel', stylebox)

func _process(_delta):
	if combatant != null:
		hp_text.text = '%s/%s' % [combatant.stat_values['health'], combatant.base_stat_values['health']]
		hp_val.value = combatant.stat_values['health']
		hp_val.max_value = combatant.base_stat_values['health']
		brawn_val.value = combatant.stat_values['brawn'] * 100
		grit_val.value = combatant.stat_values['grit'] * 100
		handling_val.max_value = 4
		handling_val.value = combatant.stat_values['handling']
		if combatant.stat_values['hustle'] >= -99:
			hustle_val.text = str(combatant.stat_values['hustle'])
		else:
			hustle_val.text = 'IMMOBILIZED'
		acc_val.value = combatant.stat_values['accuracy'] * 100
		crit_d_val.text = str(combatant.stat_values['crit_dmg'])
		crit_val.value = combatant.stat_values['crit'] * 100
		resist_val.value = combatant.stat_values['resist'] * 100
		if combatant.stat_values['heal_mult'] > 0:
			healm_val.text = str(combatant.stat_values['heal_mult'])
		else:
			healm_val.text = 'BROKEN'
		# Abilities
		if view_abilities:
			abilities_label.text = getAbilities(combatant)
			abilities_label.show()
	
		#highlightModifiedStats(hp_val, 'health')
		highlightModifiedStats(brawn_val, 'brawn')
		highlightModifiedStats(grit_val, 'grit')
		highlightModifiedStats(handling_val, 'handling')
		highlightModifiedStats(hustle_val, 'hustle')
		highlightModifiedStats(acc_val, 'accuracy')
		highlightModifiedStats(crit_d_val, 'crit_dmg')
		highlightModifiedStats(crit_val, 'crit')
		highlightModifiedStats(resist_val, 'resist')
		highlightModifiedStats(healm_val, 'heal_mult')

func highlightModifiedStats(value_node, stat):
	if combatant.stat_values[stat] > combatant.base_stat_values[stat]:
		value_node.modulate = Color.PALE_GREEN
	elif combatant.stat_values[stat] < combatant.base_stat_values[stat]:
		value_node.modulate = Color.PALE_VIOLET_RED
	else:
		value_node.modulate = Color.WHITE

func getAbilities(view_combatant:ResCombatant):
	var ability_set = '[table=2]'
	
	for ability in view_combatant.ability_set:
		ability_set += '[cell][hint='+ability.description+']'+ability.name + '[/hint][/cell][cell]' + ability.getPositionIcon(true, combatant is ResEnemyCombatant)+'[/cell]\n'
	
	ability_set += '[/table]'
	return ability_set

func formatModifiers(stat_dict: Dictionary) -> String:
	var result = ""
	for key in stat_dict.keys():
		var value = stat_dict[key]
		if value is float: 
			value *= 100.0
		if stat_dict[key] > 0 and stat_dict[key]:
			if value is float: 
				result += "+" + str(value) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(value) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			if value is float: 
				result += str(value) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(value) + " " +key.to_upper().replace('_', ' ') + "\n"
	return result
