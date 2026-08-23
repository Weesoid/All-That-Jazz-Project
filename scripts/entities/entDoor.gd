extends Area2D
class_name Door

@export var to_scene_path: String
@export var to_coords: String = '0,0'
@export var teleport_coords:Vector2 = Vector2.ZERO
@export var touch_enter: bool = true
@export var fade_color:Color= Color.BLACK
@export var fade_in_time:=0.25
@export var fade_out_time:=0.25

func interact():
#	if PlayerGlobals.isMapCleared():
	#	visible = true
	
	if teleport_coords != Vector2.ZERO:
		OverworldGlobals.setPlayerInput(false)
		await OverworldGlobals.showCameraOverlay(fade_color.to_html(), fade_in_time)
		#OverworldGlobals.player.walking_animations.play('Idle_Down')
		OverworldGlobals.moveEntity('Player', '>D12')
		OverworldGlobals.player.global_position = teleport_coords
		await get_tree().create_timer(0.5).timeout
		OverworldGlobals.setPlayerInput(true)
		OverworldGlobals.showCameraOverlay('transparent', fade_out_time)
	else:
		OverworldGlobals.changeMap(to_scene_path, to_coords)
	#else:
	#	visible = false
		#OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")

func _on_body_entered(body):
	if touch_enter:
		interact()
#	if touch_enter and body is PlayerScene and PlayerGlobals.isMapCleared(): 
#		visible = true
#	elif touch_enter and body is PlayerScene:
#		visible = false
		#OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")
