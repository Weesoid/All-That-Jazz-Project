extends Control

@onready var buttons= $VBoxContainer
@onready var end_sentence = $EndSentence
@onready var animator = $AnimationPlayer
@onready var saves = $Saves

func _ready():
	animator.play('Show')
	await animator.animation_finished
	OverworldGlobals.setMenuFocus(buttons)

func _on_yes_pressed():
	saves.show()
	OverworldGlobals.setMenuFocus(saves.panel)
	for child in buttons.get_children():
		child.focus_mode = Control.FOCUS_NONE

# Go to main menu!
func _on_no_button_down():
	get_tree().quit()
