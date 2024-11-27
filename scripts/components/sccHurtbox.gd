extends Node

@export var HIT_SCRIPT: GDScript
var BODY: CharacterBody2D

func _ready():
	BODY = get_parent()

func applyEffect():
	HIT_SCRIPT.applyEffect(BODY)
