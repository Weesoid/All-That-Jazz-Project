extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var show_ui:bool = false
@export var move_player: bool = true
@export var go_left: bool = false
@export var show_followers: bool = true
@export var move_followers:bool = false
@export var cooldown: float = 1.0

@onready var cooldown_timer = $Timer
var direction:int=1

func _ready():
	if go_left:
		direction = -1
	centerSelf()

func centerSelf():
	if get_parent().has_node('CollisionShape2D'):
		position.x = 0
		position.y = -(get_parent().get_node('CollisionShape2D').shape.height/2)

func interact():
	if dialogue_resource == null:
		OverworldGlobals.showPrompt('YOU FORGOT TO PUT IN DIALOGUE STUPID!!!!!!!!!!!!!!!')
		return
	if !cooldown_timer.is_stopped():
		return
	
	await enter()
	if get_parent().has_method('interact'):
		await get_parent().interact()
	OverworldGlobals.showDialogueBox(dialogue_resource, dialogue_start)
	if !show_ui:
		await DialogueManager.dialogue_ended
	if get_parent().has_method('exit'):
		await get_parent().exit()
	exit()
	
func moveFollowers():
	for follower in PlayerGlobals.getActiveFollowers():
		OverworldGlobals.moveEntity(str(follower.name), follower.getFollowPoint(Vector2(direction,0)))
		follower.get_node('ScriptedMovementComponent').movement_finished.connect(
			func():
				await get_tree().process_frame
				follower.updateSprite()
				follower.stopWalkAnimation()
				)

func  enter():
	cooldown_timer.start(cooldown)
	# Disable inputs /  Hide UI
	OverworldGlobals.player.player_camera.cinematic_bars.visible = true
	#OverworldGlobals.player.playAudio("sounds118228__joedeshon__raising_phone_handset.ogg", 0.0, true)
	#get_tree().create_tween().tween_property(OverworldGlobals.player.player_camera, 'zoom', Vector2(3, 3), 0.5)
	OverworldGlobals.setPlayerInput(false)
	OverworldGlobals.player.setUIVisibility(false)
	OverworldGlobals.player.sprinting = false
	OverworldGlobals.setMouseController(true)
	#OverworldGlobals.setMouseController(true)
	#OverworldGlobals.zoomCamera(Vector2(3,3))
	PlayerGlobals.setFollowersMotion(false)
	
	# Move player
	if move_player:
		await OverworldGlobals.moveEntity("Player", str(get_parent().name), Vector2(48*direction,0))
		if go_left:
			await OverworldGlobals.moveEntity("Player", ">R2")
		else:
			await OverworldGlobals.moveEntity("Player", ">L2")
	if show_followers and move_followers:
		await moveFollowers()
	elif !show_followers:
		OverworldGlobals.fadeFollowers(Color.TRANSPARENT)


func exit():
	# Enable inputs
	OverworldGlobals.player.player_camera.cinematic_bars.visible = false
	OverworldGlobals.player.setUIVisibility(true)
	if !OverworldGlobals.inMenu():
		#print('DBox setting to true!')
		if !OverworldGlobals.inCombat(): OverworldGlobals.setMouseController(false)
		OverworldGlobals.setPlayerInput(true)
	
	# Reset player stuff
	if !show_followers:
		OverworldGlobals.fadeFollowers(Color.WHITE)
	if OverworldGlobals.player.player_camera.position != OverworldGlobals.player.default_camera_pos:
		OverworldGlobals.moveCamera('RESET',0.5)
	if OverworldGlobals.player.player_camera.zoom != Vector2(1,1):
		OverworldGlobals.zoomCamera(Vector2(1,1),0.5)
	PlayerGlobals.setFollowersMotion(true)
	cooldown_timer.start(cooldown)

