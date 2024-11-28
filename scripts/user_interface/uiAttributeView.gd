extends Control

@export var borders = true
@export var view_hidden = true

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
@onready var temperments = $Temperments
@onready var p_temp_name = $Temperments/MarginContainer/VBoxContainer/PrimaryTemperment/Label
@onready var p_temp_val = $Temperments/MarginContainer/VBoxContainer/PrimaryTemperment/Values
@onready var s_temp_name = $Temperments/MarginContainer/VBoxContainer/SecondaryTemperment/Label
@onready var s_temp_val = $Temperments/MarginContainer/VBoxContainer/SecondaryTemperment/Values

func _ready():
	if !borders:
		var stylebox:StyleBox = preload("res://design/BorderlessContiner.tres")
		attribute_tab.add_theme_stylebox_override('panel', stylebox)
		hidden_tab.add_theme_stylebox_override('panel', stylebox)

func _process(_delta):
	if combatant != null:
		# Stats
		hp_text.text = '%s/%s' % [combatant.STAT_VALUES['health'], combatant.BASE_STAT_VALUES['health']]
		hp_val.value = combatant.STAT_VALUES['health']
		hp_val.max_value = combatant.BASE_STAT_VALUES['health']
		brawn_val.value = combatant.STAT_VALUES['brawn'] * 100
		grit_val.value = combatant.STAT_VALUES['grit'] * 100
		handling_val.max_value = 4
		handling_val.value = combatant.STAT_VALUES['handling']
		if combatant.STAT_VALUES['hustle'] >= -99:
			hustle_val.text = str(combatant.STAT_VALUES['hustle'])
		else:
			hustle_val.text = 'IMMOBILIZED'
		# Hidden Stats
		acc_val.value = combatant.STAT_VALUES['accuracy'] * 100
		crit_d_val.text = str(combatant.STAT_VALUES['crit_dmg'])
		crit_val.value = combatant.STAT_VALUES['crit'] * 100
		resist_val.value = combatant.STAT_VALUES['resist'] * 100
		healm_val.text = str(combatant.STAT_VALUES['heal_mult'])
		# Temperments
		if combatant is ResPlayerCombatant and combatant.TEMPERMENT != {'primary':'', 'secondary':''}:
			temperments.show()
			p_temp_name.text = combatant.TEMPERMENT['primary']
			p_temp_val.text = formatModifiers(combatant.STAT_MODIFIERS['primary_temperment'])
			s_temp_name.text = combatant.TEMPERMENT['secondary']
			s_temp_val.text = formatModifiers(combatant.STAT_MODIFIERS['secondary_temperment'])
		else:
			temperments.hide()
		if OverworldGlobals.isPlayerCheating():
			debug_status.visible = OverworldGlobals.getPlayer().get_node('DebugComponent').visible
			debug_status.text = str(combatant.STAT_MODIFIERS)

func formatModifiers(stat_dict: Dictionary) -> String:
	var result = ""
	for key in stat_dict.keys():
		var value = stat_dict[key]
		if value is float: 
			value *= 100.0
		if stat_dict[key] > 0 and stat_dict[key]:
			result += '[color=GREEN_YELLOW]'
			if value is float: 
				result += "+" + str(value) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(value) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			result += '[color=ORANGE_RED]'
			if value is float: 
				result += str(value) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(value) + " " +key.to_upper().replace('_', ' ') + "\n"
		result += '[/color]'
	return result

