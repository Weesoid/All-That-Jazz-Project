extends Node2D
class_name SavePoint

#const EMPTY_MEMBER_ICON = preload("res://images/sprites/add_member.png")

@export var music_paths: Array[String] = []
@export var mind_rested:bool=true
@onready var rest_spots = $RestSpots
@onready var animator = $AnimationPlayer
@onready var music = $Music
@onready var ambience = $Ambience
@onready var flame_sprite = $Flame
@onready var kindle_slot = $UI/KindlingSlot
@onready var heads_up_cd = $HeadsUpCooldown
@onready var ui_layer = $UI
var camp_music:Array[String]=[
	"res://audio/music/579851__zhr__relaxation-loop-4.ogg", 
	"res://audio/music/614096__zhr__calm-emtim-bell-music.ogg"
]
var rest_cam_offset = Vector2(0,-48)
var menu_cam_offset = Vector2(44,-32)
var fire_kindled:bool=false
var combatant_squad: EnemyCombatantSquad
signal done
signal ambush_ended
signal sprite_added(combatant,slot)
#signal camp_kindled


func _ready():
	done.connect(exit)
	loadCombatantSquad()

func loadCombatantSquad():
	if OverworldGlobals.getCurrentMap().occupying_faction == null:
		return
	
	combatant_squad = CombatGlobals.generateCombatantSquad(null,OverworldGlobals.getCurrentMap().occupying_faction)
	combatant_squad.can_escape = false
	add_child(combatant_squad)

func fightCombatantSquad():
	if combatant_squad == null:
		return
	
	OverworldGlobals.changeToCombat(name)
	await OverworldGlobals.combat_exited
	ambush_ended.emit()

func interact():
	OverworldGlobals.start_camp.emit()
	music.stream=load(camp_music.pick_random())
	SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	OverworldGlobals.player.camping=true
	OverworldGlobals.player.current_camp_spot = self
	OverworldGlobals.destroyAllPatrollers(true)
	OverworldGlobals.setPlayerInput(false)
	#await OverworldGlobals.player.player_camera.flashOverlay(Color.RED,1.0)
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 0.5)
	#PlayerGlobals.overworld_stats['stamina'] = 100.0
	OverworldGlobals.fadeFollowers(Color.TRANSPARENT)
	#if OverworldGlobals.getCurrentMap().map_properties.has(MapData.MapProperties.COLD):
	#	animator.play("Lit")
	OverworldGlobals.moveCamera(self,0,Vector2(0,-32))
	await OverworldGlobals.zoomCamera(Vector2(2,2),0.5,true)
	OverworldGlobals.player.sprite.hide()
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		addRestSprite(combatant)
	await OverworldGlobals.player.player_camera.showOverlay(Color.TRANSPARENT,0.5)
	OverworldGlobals.moveCamera(self,.75,menu_cam_offset)

func exit():
	await done
	OverworldGlobals.end_camp.emit()
	music.stop()
	ambience.stop()
	animator.play("RESET")
	for member in PlayerGlobals.team:
		member.removeTemporaryModifier('Warmth')
	OverworldGlobals.fadeFollowers(Color.WHITE)
	
	for bar in ui_layer.get_children():
		removeRestSprite(bar.attached_combatant)
	for sprite in rest_spots.get_children():
		sprite.texture = null
	OverworldGlobals.player.sprite.show()
	OverworldGlobals.player.player_camera.showOverlay(Color.TRANSPARENT,0.5)
	#kindle_slot.setDisabled(false)
	fire_kindled=false
	await get_tree().process_frame
	OverworldGlobals.player.camping=false
	OverworldGlobals.player.current_camp_spot=null
	SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	await get_tree().process_frame
	OverworldGlobals.moveCamera("RESET",0.5)
	OverworldGlobals.zoomCamera(Vector2(1,1),0.5)
	OverworldGlobals.setPlayerInput(true)

func addRestSprite(combatant: ResPlayerCombatant,pos:int=-1):
	if pos >= 0:
		var sprite = rest_spots.get_children()[pos]
		setSprite(sprite,combatant)
		return
	
	for sprite in rest_spots.get_children():
		if sprite.texture != null: 
			continue
		setSprite(sprite,combatant)
		return

func setSprite(sprite: Sprite2D, combatant:ResPlayerCombatant):
	var combat_bar_idx = sprite.name.trim_prefix('Sprite2D')
	var combat_bar = ui_layer.get_node('CombatBars'+combat_bar_idx)
	sprite.modulate = Color.BLACK
	sprite.texture = combatant.rest_sprite
	combat_bar.setCombatant(combatant)
	combat_bar.fader_bar.modulate = Color.WHITE
	combat_bar.health_bar.modulate = Color.WHITE
	combat_bar.show()
	sprite_added.emit(combatant, combat_bar_idx)
	create_tween().tween_property(sprite,'modulate',Color.WHITE,0.5)

func removeRestSprite(character:ResPlayerCombatant):
	for sprite in ui_layer.get_children():
		if sprite.attached_combatant == null:
			continue
		if sprite.attached_combatant == character:
			#sprite.texture = null
			sprite.setConnections(false)
			sprite.attached_combatant = null
			sprite.hide()

func showEmptyMembers():
	for sprite in rest_spots.get_children():
		if sprite.texture == null:
			#sprite.texture = EMPTY_MEMBER_ICON
			sprite.get_node('CombatBars').fader_bar.modulate = Color.TRANSPARENT
			sprite.get_node('CombatBars').health_bar.modulate = Color.TRANSPARENT
			sprite.get_node('CombatBars').show()

func hideEmptyMembers():
	for sprite in rest_spots.get_children():
		if sprite.texture == null:
			sprite.texture = null
			sprite.get_node('CombatBars').hide()

func getResterPosition(character: ResPlayerCombatant)-> String:
	for bar in getCombatBars(true):
		#var bar = rest_spots.get_children()[i].get_node('CombatBars')
		if bar.attached_combatant == character:
			return bar.name.trim_prefix('CombatBars')
	
	return '-1'

func setBarVisibility(set_to:bool):
	for sprite in rest_spots.get_children():
		if sprite.texture != null: sprite.get_node('CombatBars').visible = set_to

func getRestSprite(combatant: ResPlayerCombatant):
	for sprite in rest_spots.get_children():
		if sprite.texture == null: continue
		
		if sprite.get_node('CombatBars').attached_combatant == combatant:
			return sprite

func getCombatBars(only_visible:bool)-> Array[CombatBarsMini]:
	var out: Array[CombatBarsMini] = []
	for control in ui_layer.get_children():
		if !control is CombatBarsMini or (only_visible and control.attached_combatant == null):
			continue
		out.append(control)
	return out

func getCombatantBar(combatant:ResPlayerCombatant):
	for bar in getCombatBars(true):
		if bar.attached_combatant == combatant: return bar

func toggleAnimFlip():
	flame_sprite.flip_h = !flame_sprite.flip_h

func getCampBars():
	var out = []
	for child in ui_layer.get_children():
		if child is CombatBarsMini: out.append(child)
	return out

func setCamToRestPos():
	OverworldGlobals.moveCamera(self,0.5,rest_cam_offset)

func setCamToMenuPos():
	OverworldGlobals.moveCamera(self,0.5,menu_cam_offset)

func grabFocus():
	print(getCombatBars(true))
	getCombatBars(true)[0].camp_button.grab_focus()

func kindleFire():
	if fire_kindled:
		return
	#O#verworldGlobals.playSound("res://audio/sounds/149831__villen__zapalenie_ognia.ogg")
	for member in OverworldGlobals.getCombatantSquad('Player'):
		member.addTemporaryModifer('Warmth',1,{CombatExtras.HEAL_AMP:0.1},false)
		CombatGlobals.healResolve(member, 1)
	music.play()
	ambience.play()
	animator.play("Lit")
	fire_kindled=true
	OverworldGlobals.getCamera().flash(Color.ORANGE,0.5,0.05,2.0)


#func _on_visible_on_screen_notifier_2d_screen_entered():
#	print('hello! ')
