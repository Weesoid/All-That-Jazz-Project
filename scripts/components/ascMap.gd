extends Node2D
class_name MapData

@export var NAME: String
@export_multiline var DESCRIPTION: String
@export var IMAGE: Texture
var done_loading_map:bool = false

func _ready():
	if SaveLoadGlobals.is_loading:
		await SaveLoadGlobals.done_loading
	if !has_node('Player'): 
		hide()
	await get_tree().process_frame
	done_loading_map = true
