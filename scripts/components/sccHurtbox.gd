extends Node

@export var hit_script: GDScript
var body: CharacterBody2D

func _ready():
	body = get_parent()

func applyEffect():
	hit_script.applyEffect(body)
