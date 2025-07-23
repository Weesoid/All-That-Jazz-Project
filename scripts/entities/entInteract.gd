extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var move_player: bool = true
@export var go_left: bool = false
@export var show_followers: bool = true
@export var move_followers:bool = false
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
	
	PlayerGlobals.setFollowersMotion(false)
	OverworldGlobals.getPlayer().sprinting = false
	if move_player:
		await OverworldGlobals.moveEntity("Player", str(get_parent().name), Vector2(48*direction,0))
		if go_left:
			await OverworldGlobals.moveEntity("Player", ">R2")
		else:
			await OverworldGlobals.moveEntity("Player", ">L2")
	if show_followers and move_followers:
		await moveFollowers()
	elif !show_followers:
		fadeFollowers(Color.TRANSPARENT)
	OverworldGlobals.showDialogueBox(dialogue_resource, dialogue_start)
	await DialogueManager.dialogue_ended
	if !show_followers:
		fadeFollowers(Color.WHITE)
	if OverworldGlobals.getPlayer().player_camera.position != OverworldGlobals.getPlayer().default_camera_pos:
		OverworldGlobals.moveCamera('RESET',1.0)
	if OverworldGlobals.getPlayer().player_camera.zoom != Vector2(1,1):
		OverworldGlobals.zoomCamera(Vector2(1,1),1.0)
	PlayerGlobals.setFollowersMotion(true)

func moveFollowers():
	for follower in PlayerGlobals.getActiveFollowers():
		OverworldGlobals.moveEntity(str(follower.name), follower.getFollowPoint(Vector2(direction,0)))
		follower.get_node('ScriptedMovementComponent').movement_finished.connect(
			func():
				await get_tree().process_frame
				follower.updateSprite()
				follower.stopWalkAnimation()
				)

func fadeFollowers(color: Color):
	for follower in PlayerGlobals.getActiveFollowers():
		follower.fade(color)

