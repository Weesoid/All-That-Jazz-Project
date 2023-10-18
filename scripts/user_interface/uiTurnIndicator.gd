extends Control

@onready var combatant_names = $CombatantNames
@onready var animator = $AnimationPlayer

var COMBATANTS: Array[ResCombatant]
var active_combatant: ResCombatant

func initialize():
	for combatant in COMBATANTS:
		var combatant_name = Label.new()
		combatant_name.add_theme_font_size_override('font_size', 16)
		combatant_name.text = combatant.NAME
		combatant_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		combatant_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		combatant_names.add_child(combatant_name)

func updateActive(combatant: ResCombatant):
	animator.play("Update")
	for label in combatant_names.get_children():
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if label.text == combatant.NAME:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
