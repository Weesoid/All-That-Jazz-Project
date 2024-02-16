extends Area2D

@export var TO_SCENE_PATH: String

func interact():
	get_tree().change_scene_to_file(TO_SCENE_PATH)
