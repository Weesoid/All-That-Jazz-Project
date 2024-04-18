extends Control

@onready var turn_container = $CombatantNames
var COMBAT_SCENE: CombatScene

func updateActive():
	for child in turn_container.get_children():
		child.free()
	
	for combatant in COMBAT_SCENE.combatant_turn_order:
		if combatant.ACTED:
			continue
		if turn_container.get_child_count() >= 4:
			break
		
		var icon = createIcon(combatant)
		turn_container.add_child(icon)
		if combatant == COMBAT_SCENE.active_combatant:
			icon.position = icon.position + Vector2(0, -15)

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
