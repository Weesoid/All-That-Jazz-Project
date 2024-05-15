extends Control

@onready var turn_container = $CombatantNames
var COMBAT_SCENE: CombatScene

func updateActive():
	for child in turn_container.get_children():
		child.queue_free()
	
	for data in COMBAT_SCENE.combatant_turn_order:
		var combatant = data[0]
		if combatant.ACTED: continue
		var icon = createIcon(combatant)
		turn_container.add_child(icon)

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
