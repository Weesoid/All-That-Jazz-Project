extends Node
class_name MapData

@export var NAME: String
@export var DESCRIPTION: String
@export var IMAGE: Texture
@export var SAFE: bool = false
var CLEARED: bool = false

func _ready():
	if !SAFE:
		clearPatrollers()

func clearPatrollers():
	await SaveLoadGlobals.done_loading
	if PlayerGlobals.CLEARED_MAPS.has(NAME):
		CLEARED = true
