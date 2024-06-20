extends Area2D

@export var TO_SCENE_PATH: String
@export var TO_COORDS: String = '0,0'

func interact():
	OverworldGlobals.changeMap(TO_SCENE_PATH, TO_COORDS)
