extends Node2D
class_name SavePoint

@export var music_paths: Array[String] = []
@onready var rest_spots = $RestSpots
@onready var animator = $AnimationPlayer
@onready var music = $AudioStreamPlayer
@onready var sfx = $AudioStreamPlayer2

var mini_bars = []
#@onready var player = 
signal done

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
	player.sprite.show()
	mini_bars = []
	await player.player_camera.hideOverlay(1.5)

func addRestSprite(combatant: ResPlayerCombatant):
	for sprite in rest_spots.get_children():
		if sprite.texture != null: continue
		sprite.texture = combatant.rest_sprite
		addCombatBar(combatant, sprite)
		return

func addCombatBar(combatant:ResPlayerCombatant,rest_texture:Sprite2D):
	var combat_bars = preload("res://scenes/user_interface/CombatBarsMini.tscn").instantiate()
	combat_bars.attached_combatant = combatant
	rest_texture.add_child(combat_bars)
	combat_bars.hide()
	mini_bars.append(combat_bars)

func setBarVisibility(set_to:bool):
	for bar in mini_bars:
		bar.visible = set_to
