extends Area2D
class_name Door

@export var TO_SCENE_PATH: String
@export var TO_COORDS: String = '0,0'
@export var TOUCH_ENTER: bool = true

func interact():
	if PlayerGlobals.isMapCleared():
		visible = true
		OverworldGlobals.changeMap(TO_SCENE_PATH, TO_COORDS)
	else:
		visible = false
		OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")

func _on_body_entered(body):
	if TOUCH_ENTER and body is PlayerScene and PlayerGlobals.isMapCleared(): 
		visible = true
		OverworldGlobals.changeMap(TO_SCENE_PATH, TO_COORDS)
	elif TOUCH_ENTER and body is PlayerScene:
		visible = false
		OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")
