extends Area2D

@export var TO_SCENE_PATH: String
@export var TO_COORDS: String = '0,0'
@export var TOUCH_ENTER: bool = true

func interact():
	OverworldGlobals.changeMap(TO_SCENE_PATH, TO_COORDS)


func _on_body_entered(body):
	if TOUCH_ENTER and body is PlayerScene:
		OverworldGlobals.changeMap(TO_SCENE_PATH, TO_COORDS)
