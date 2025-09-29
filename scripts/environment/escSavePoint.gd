extends Node2D
class_name SavePoint

@export var music_paths: Array[String] = []
@export var mind_rested:bool=true
@onready var rest_spots = $RestSpots
@onready var animator = $AnimationPlayer
@onready var music = $AudioStreamPlayer
@onready var sfx = $AudioStreamPlayer2
@onready var watch_mark = $Sprite2D2
@onready var watch_mark_animator = $Sprite2D2/AnimationPlayer
#var mini_bars = []
var combatant_squad: ResEnemyCombatant
signal done

func loadCombatantSquad():
	add_child(CombatGlobals.generateCombatantSquad(null,CombatGlobals.Enemy_Factions.Scavs)) # Changge to current map faction later

func fightCombatantSquad():
	OverworldGlobals.changeToCombat(name)

func interact():
	SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	OverworldGlobals.player.camping=true
	OverworldGlobals.destroyAllPatrollers(true)
	OverworldGlobals.setPlayerInput(false)
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	PlayerGlobals.overworld_stats['stamina'] = 100.0
	OverworldGlobals.fadeFollowers(Color.TRANSPARENT)
	animator.play("Lit")
	OverworldGlobals.moveCamera(self, 0, Vector2(0,-30))
	await OverworldGlobals.zoomCamera(Vector2(3,3),1,true)
	OverworldGlobals.player.sprite.hide()
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		addRestSprite(combatant)
	await OverworldGlobals.player.player_camera.hideOverlay(1.5)

func exit():
	await done
	animator.play("RESET")
	OverworldGlobals.fadeFollowers(Color.WHITE)
	for sprite in rest_spots.get_children():
		if sprite.has_node('CombatBars'):
			sprite.get_node('CombatBars').attached_combatant = null
			sprite.get_node('CombatBars').hide()
	for sprite in rest_spots.get_children():
		sprite.texture = null
	watch_mark_animator.play("RESET")
	OverworldGlobals.player.sprite.show()
	OverworldGlobals.player.player_camera.hideOverlay(1.5)
	await get_tree().process_frame
	OverworldGlobals.player.camping=false
	SaveLoadGlobals.saveGame(PlayerGlobals.save_name)

func addRestSprite(combatant: ResPlayerCombatant):
	for sprite in rest_spots.get_children():
		if sprite.texture != null: 
			continue
		sprite.texture = combatant.rest_sprite
		sprite.get_node('CombatBars').attached_combatant = combatant
		sprite.get_node('CombatBars').show()
		return

func setBarVisibility(set_to:bool):
	for sprite in rest_spots.get_children():
		if sprite.texture != null: sprite.get_node('CombatBars').visible = set_to

func showWatchMark(combatant: ResPlayerCombatant, reverse:bool=false):
	watch_mark.global_position = getRestSprite(combatant).global_position
	if reverse:
		watch_mark_animator.play_backwards("Show")
	else:
		watch_mark_animator.play("RESET")
		await watch_mark_animator.animation_finished
		watch_mark_animator.play("Show")

func getRestSprite(combatant: ResPlayerCombatant):
	for sprite in rest_spots.get_children():
		if sprite.texture == null: continue
		
		if sprite.get_node('CombatBars').attached_combatant == combatant:
			return sprite
