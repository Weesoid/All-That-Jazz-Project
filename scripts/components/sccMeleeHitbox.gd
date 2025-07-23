extends Area2D
class_name MeleeHitbox

@onready var player = OverworldGlobals.getPlayer()
@onready var smear = $AnimationPlayer

func _on_body_entered(body):
	if OverworldGlobals.entering_combat:
		return
	if body is GenericPatroller and is_instance_valid(body):
		if body.has_node('CombatInteractComponent'):
			body.destroy(true)
			PlayerGlobals.overworld_stats['stamina'] -= 50
			OverworldGlobals.shakeCamera()
			await OverworldGlobals.getPlayer().player_camera.showOverlay(Color.RED, 0.025)
			OverworldGlobals.getPlayer().player_camera.hideOverlay()
		elif body.state != 3:
			body.combat_switch = false
			OverworldGlobals.changeToCombat(body.name, {'initial_damage'=float(0.2)},body)
	if body.has_node('Sprite2D') and body != player:
		OverworldGlobals.shakeSprite(body,  5.0, 10.0)

func _unhandled_input(event):
	if Input.is_action_just_pressed('ui_melee') and player.canMelee():
		smear.play('Show')

func getTileTexture(tile_set):
	for tile_set_id in tile_set.get_source_count():
		var atlas: TileSetAtlasSource = tile_set.get_source(tile_set_id)
		print(atlas.texture.resource_path)
