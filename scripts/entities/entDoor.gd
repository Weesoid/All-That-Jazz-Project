extends Area2D
class_name Door

@export var to_scene_path: String
@export var to_coords: String = '0,0'
@export var touch_enter: bool = true

func interact():
	if PlayerGlobals.isMapCleared():
		visible = true
		OverworldGlobals.changeMap(to_scene_path, to_coords)
	else:
		visible = false
		OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")

func _on_body_entered(body):
	if touch_enter and body is PlayerScene and PlayerGlobals.isMapCleared(): 
		visible = true
		OverworldGlobals.changeMap(to_scene_path, to_coords)
	elif touch_enter and body is PlayerScene:
		visible = false
		OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")
