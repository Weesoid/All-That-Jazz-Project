extends Node

@export var BODY: CharacterBody2D
@export var SCENE: Node2D
@export var HIT_SCRIPT: GDScript

func applyEffect():
	print('From hbox')
	HIT_SCRIPT.applyEffect(BODY, SCENE)
	


