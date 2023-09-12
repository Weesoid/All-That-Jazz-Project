extends Node2D

@onready var bottom_menu = $Info/Label
@onready var side_menu = $Stats/Label

var subject

func _process(_delta):
	if subject is ResCombatant:
		side_menu.text = subject.getStringCurrentStats()
		bottom_menu.text = subject.DESCRIPTION
