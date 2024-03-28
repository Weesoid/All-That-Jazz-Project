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
		var icon = createIcon(combatant)
		if combatant.ACTED:
			icon.modulate.a = 0.5
#		else:
#			combatant_name.add_theme_color_override('font_outline_color', Color.DIM_GRAY)
#		combatant_name.self_modulate = Color.YELLOW
#		combatant_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
#		combatant_name.text = combatant.NAME
#		combatant_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
#		if combatant.isDead():
#			combatant_name.modulate.a = 0.5
		print('Adding!')
		combatant_names.add_child(icon)

func updateActive():
	initialize()
#	animator.play("Update")
#	initialize()
#	for label in combatant_names.get_children():
#		label.text.replace(' <', '')
#		label.self_modulate = Color.WHITE
#		label.add_theme_constant_override('outline_size', 8)
#		if COMBAT_SCENE.active_combatant.NAME == label.text:
#			label.self_modulate = Color.YELLOW
#			label.add_theme_constant_override('outline_size', 16)
#			label.text += ' <'

func createIcon(combatant: ResCombatant):
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.region = Rect2(0, 0, 256, 256)
	atlas.atlas = combatant.SCENE.get_node('Sprite').texture
	icon.texture = atlas
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	return icon
