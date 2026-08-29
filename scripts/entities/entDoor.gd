extends Area2D
class_name Door

enum FaceDirection {
	NONE,
	LEFT,
	RIGHT,
	UP,
	DOWN
}

@export var to_scene_path: String
@export var to_coords: String = '0,0'
@export var teleport_coords:Vector2 = Vector2.ZERO
@export var touch_enter: bool = false
@export var fade_color:Color= Color.BLACK
@export var fade_in_time:=0.25
@export var fade_out_time:=0.25
@export var offset := Vector2.ZERO
@export var face_direction: FaceDirection = FaceDirection.NONE
@export var interact_direction: FaceDirection = FaceDirection.NONE

func interact():
#	if !OverworldGlobals.player.canInteract(): return
	
	OverworldGlobals.player.suddenStop()
	OverworldGlobals.setPlayerInput(false)
	await changePlayerDirection(interact_direction)
	if teleport_coords != Vector2.ZERO:
		await OverworldGlobals.showCameraOverlay(fade_color.to_html(), fade_in_time)
		OverworldGlobals.player.global_position = teleport_coords + offset
		await changePlayerDirection(face_direction)
		await get_tree().create_timer(0.3).timeout
		OverworldGlobals.setPlayerInput(true)
		OverworldGlobals.showCameraOverlay('transparent', fade_out_time)
	else:
		OverworldGlobals.changeMap(to_scene_path, to_coords)
	#else:
	#	visible = false
		#OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")

func changePlayerDirection(direction):
	if direction == FaceDirection.NONE:
		return
	
	var direction_seq
	match direction:
		FaceDirection.LEFT: direction_seq = '>L1' 
		FaceDirection.RIGHT: direction_seq = '>R1'
		#FaceDirection.DOWN: direction_seq = '>^D'
		#FaceDirection.UP: direction_seq = '>^U'
	await OverworldGlobals.moveEntity('Player',direction_seq)

func _on_body_entered(body):
	if touch_enter:
		interact()
#	if touch_enter and body is PlayerScene and PlayerGlobals.isMapCleared(): 
#		visible = true
#	elif touch_enter and body is PlayerScene:
#		visible = false
		#OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")
