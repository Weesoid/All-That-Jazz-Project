extends Control

@onready var combatant_names = $CombatantNames

var COMBAT_SCENE: CombatScene

func updateActive():
	var tween = create_tween()
	for child in combatant_names.get_children():
		child.free()
	
	for combatant in COMBAT_SCENE.combatant_turn_order:
		if combatant.ACTED:
			continue
		if combatant_names.get_child_count() >= 4:
			break
		
		var icon = createIcon(combatant)
		combatant_names.add_child(icon)
		if combatant == CombatGlobals.getCombatScene().active_combatant:
			tween.tween_property(icon, 'position', icon.position + Vector2(0, -15), 0.25)

func createIcon(combatant: ResCombatant):
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.region = Rect2(0, 0, 256, 256)
	atlas.atlas = combatant.SCENE.get_node('Sprite').texture
	icon.texture = atlas
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	if combatant.hasStatusEffect('Fading'):
		icon.modulate.a = 0.25
	return icon
