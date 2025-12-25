extends Node2D
class_name SavePoint

const EMPTY_MEMBER_ICON = preload("res://images/sprites/add_member.png")

@export var music_paths: Array[String] = []
@export var mind_rested:bool=true
@onready var rest_spots = $RestSpots
@onready var animator = $AnimationPlayer
@onready var music = $AudioStreamPlayer
@onready var sfx = $AudioStreamPlayer2
@onready var watch_mark = $Sprite2D2
@onready var watch_mark_animator = $Sprite2D2/AnimationPlayer
#var mini_bars = []
var combatant_squad: EnemyCombatantSquad
signal done

func loadCombatantSquad():
	combatant_squad = CombatGlobals.generateCombatantSquad(null,CombatGlobals.Enemy_Factions.Scavs)
	combatant_squad.can_escape = false
	add_child(combatant_squad) # Changge to current map faction later

func fightCombatantSquad():
	OverworldGlobals.changeToCombat(name)

func interact():
	SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	OverworldGlobals.player.camping=true
	OverworldGlobals.destroyAllPatrollers(true)
	OverworldGlobals.setPlayerInput(false)
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 0.5)
	PlayerGlobals.overworld_stats['stamina'] = 100.0
	OverworldGlobals.fadeFollowers(Color.TRANSPARENT)
	if OverworldGlobals.getCurrentMap().map_properties.has(MapData.MapProperties.COLD):
		animator.play("Lit")
	OverworldGlobals.moveCamera(self,0,Vector2(0,-10))
	await OverworldGlobals.zoomCamera(Vector2(3,3),0.5,true)
	OverworldGlobals.player.sprite.hide()
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		addRestSprite(combatant)
	await OverworldGlobals.player.player_camera.hideOverlay(0.5)

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
	OverworldGlobals.player.player_camera.hideOverlay(0.5)
	await get_tree().process_frame
	OverworldGlobals.player.camping=false
	SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	await get_tree().process_frame

func addRestSprite(combatant: ResPlayerCombatant,pos:int=-1):
	if pos >= 0:
		var sprite = rest_spots.get_children()[pos]
		setSprite(sprite,combatant)
		return
	
	for sprite in rest_spots.get_children():
		if sprite.texture != null and sprite.texture != EMPTY_MEMBER_ICON: 
			continue
		setSprite(sprite,combatant)
		return

func setSprite(sprite: Sprite2D, combatant:ResPlayerCombatant):
	sprite.modulate = Color.BLACK
	sprite.texture = combatant.rest_sprite
	sprite.get_node('CombatBars').setCombatant(combatant)
	sprite.get_node('CombatBars').fader_bar.modulate = Color.WHITE
	sprite.get_node('CombatBars').health_bar.modulate = Color.WHITE
	sprite.get_node('CombatBars').show()
	create_tween().tween_property(sprite,'modulate',Color.WHITE,0.5)

func removeRestSprite(character:ResPlayerCombatant):
	for sprite in rest_spots.get_children():
		if sprite.get_node('CombatBars').attached_combatant == character:
			sprite.texture = null
			sprite.get_node('CombatBars').attached_combatant = null
			sprite.get_node('CombatBars').hide()

func showEmptyMembers():
	for sprite in rest_spots.get_children():
		if sprite.texture == null:
			sprite.texture = EMPTY_MEMBER_ICON
			sprite.get_node('CombatBars').fader_bar.modulate = Color.TRANSPARENT
			sprite.get_node('CombatBars').health_bar.modulate = Color.TRANSPARENT
			sprite.get_node('CombatBars').show()

func hideEmptyMembers():
	for sprite in rest_spots.get_children():
		if sprite.texture == EMPTY_MEMBER_ICON:
			sprite.texture = null
			sprite.get_node('CombatBars').hide()

func getResterPosition(character: ResPlayerCombatant)-> int:
	for i in range(rest_spots.get_children().size()):
		var bar = rest_spots.get_children()[i].get_node('CombatBars')
		if bar.attached_combatant == character:
			return i 
	
	return -1

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

func getCombatBars(only_visible:bool)-> Array[CombatBarsMini]:
	var out: Array[CombatBarsMini] = []
	for sprite in rest_spots.get_children():
		if only_visible and sprite.texture == null:
			continue
		out.append(sprite.get_node('CombatBars'))
	return out
