extends Control

@onready var combatant_names = $CombatantNames
@onready var animator = $AnimationPlayer

#var COMBATANTS: Array[ResCombatant]
#var active_combatant: ResCombatant
var COMBAT_SCENE: CombatScene

func initialize():
	for child in combatant_names.get_children():
		child.free()
	for combatant in COMBAT_SCENE.combatant_turn_order:
		var combatant_name = Label.new()
		combatant_name.add_theme_font_size_override('font_size', 16)
		combatant_name.add_theme_constant_override('outline_size', 8)
		if combatant.ACTED:
			combatant_name.add_theme_color_override('font_outline_color', Color.YELLOW_GREEN)
		else:
			combatant_name.add_theme_color_override('font_outline_color', Color.DIM_GRAY)
		combatant_name.self_modulate = Color.YELLOW
		combatant_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		combatant_name.text = combatant.NAME
		combatant_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if combatant.isDead():
			combatant_name.modulate.a = 0.5
		combatant_names.add_child(combatant_name)

func updateActive():
	animator.play("Update")
	initialize()
	for label in combatant_names.get_children():
		label.text.replace(' <', '')
		label.self_modulate = Color.WHITE
		label.add_theme_constant_override('outline_size', 8)
		if COMBAT_SCENE.active_combatant.NAME == label.text:
			label.self_modulate = Color.YELLOW
			label.add_theme_constant_override('outline_size', 16)
			label.text += ' <'
