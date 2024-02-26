extends Control

@export var borders = true
@onready var combatant: ResCombatant
@onready var attribute_tab = $Attributes
@onready var hidden_tab = $HiddenAttributes
@onready var hp_val = $Attributes/MarginContainer/VBoxContainer/Health/ProgressBar
@onready var brawn_val = $Attributes/MarginContainer/VBoxContainer/Brawn/ProgressBar
@onready var grit_val = $Attributes/MarginContainer/VBoxContainer/Grit/ProgressBar
@onready var handling_val = $Attributes/MarginContainer/VBoxContainer/Handling/ProgressBar
@onready var hustle_val = $Attributes/MarginContainer/VBoxContainer/Hustle/Value
@onready var acc_val = $HiddenAttributes/MarginContainer/VBoxContainer/Accuracy/ProgressBar
@onready var dodge_val = $HiddenAttributes/MarginContainer/VBoxContainer/Dodge/ProgressBar
@onready var crit_val = $HiddenAttributes/MarginContainer/VBoxContainer/Crit/ProgressBar
@onready var resist_val = $HiddenAttributes/MarginContainer/VBoxContainer/Resist/ProgressBar
@onready var healm_val = $HiddenAttributes/MarginContainer/VBoxContainer/HealMult/Value

func _ready():
	if !borders:
		print('Ready!')
		var stylebox:StyleBox = preload("res://design/BorderlessContiner.tres")
		attribute_tab.add_theme_stylebox_override('panel', stylebox)
		hidden_tab.add_theme_stylebox_override('panel', stylebox)

func _process(_delta):
	if combatant != null:
		# Stats
		hp_val.value = combatant.STAT_VALUES['health']
		brawn_val.value = combatant.STAT_VALUES['brawn'] * 100
		grit_val.value = combatant.STAT_VALUES['grit'] * 100
		handling_val.value = combatant.STAT_VALUES['handling']
		hustle_val.text = str(combatant.STAT_VALUES['hustle'])
		# Hidden Stats
		acc_val.value = combatant.STAT_VALUES['accuracy'] * 100
		dodge_val.value = combatant.STAT_VALUES['dodge'] * 100
		crit_val.value = combatant.STAT_VALUES['crit'] * 100
		resist_val.value = combatant.STAT_VALUES['crit'] * 100
		healm_val.text = str(combatant.STAT_VALUES['heal mult'])

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_tab"):
		print('x')
		hidden_tab.visible = !hidden_tab.visible
