extends Node2D
class_name MyMapData

func _ready():
	if !has_node('Player'): hide()
