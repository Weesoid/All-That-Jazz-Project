extends Area2D

@export var TO_SCENE_PATH: String

func interact():
	print(TO_SCENE_PATH)
	get_tree().change_scene_to_file(TO_SCENE_PATH)
	#OverworldGlobals.show_player_interaction = true
