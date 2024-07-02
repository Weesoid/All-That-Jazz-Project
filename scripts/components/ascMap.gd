extends Node2D

func _ready():
	if !has_node('Player'): hide()
