extends Node2D
class_name SavePoint

@export var music_paths: Array[String] = []
@onready var rest_spots = $RestSpots
@onready var animator = $AnimationPlayer
@onready var music = $AudioStreamPlayer
@onready var sfx = $AudioStreamPlayer2
@onready var watch_mark = $Sprite2D2
@onready var watch_mark_animator = $Sprite2D2/AnimationPlayer
var mini_bars = []
var combatant_squad: ResEnemyCombatant
signal done

func loadCombatantSquad():
	add_child(CombatGlobals.generateCombatantSquad(null,CombatGlobals.Enemy_Factions.Scavs)) # Changge to current map faction later

func fightCombatantSquad():
	OverworldGlobals.changeToCombat(name)

func interact():
	OverworldGlobals.setPlayerInput(false)
	var player = OverworldGlobals.getPlayer()
	await player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	animator.play("Lit")
	OverworldGlobals.moveCamera(self, 0, Vector2(0,-30))
	await OverworldGlobals.zoomCamera(Vector2(3,3),1,true)
	player.sprite.hide()
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		addRestSprite(combatant)
	await player.player_camera.hideOverlay(1.5)

func exit():
	await done
	var player = OverworldGlobals.getPlayer()
	animator.play("RESET")
	for sprite in rest_spots.get_children():
		sprite.texture = null
	for bar in mini_bars:
		bar.queue_free()
	watch_mark_animator.play("RESET")
	player.sprite.show()
	mini_bars = []
	player.player_camera.hideOverlay(1.5)
	await get_tree().process_frame

func addRestSprite(combatant: ResPlayerCombatant):
	for sprite in rest_spots.get_children():
		if sprite.texture != null: continue
		sprite.texture = combatant.rest_sprite
		addCombatBar(combatant, sprite)
		return

func addCombatBar(combatant:ResPlayerCombatant,rest_texture:Sprite2D):
	var combat_bars = preload("res://scenes/user_interface/CombatBarsMini.tscn").instantiate()
	combat_bars.attached_combatant = combatant
	combat_bars.rest_sprite = rest_texture
	#combat_bars.selector.pressed.connect()
	rest_texture.add_child(combat_bars)
	combat_bars.hide()
	mini_bars.append(combat_bars)

func setBarVisibility(set_to:bool):
	for bar in mini_bars:
		bar.visible = set_to

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
