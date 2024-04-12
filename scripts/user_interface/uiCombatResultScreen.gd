extends Control
class_name CombatResults

signal done
@onready var bonuses = $PanelContainer/MarginContainer/VBoxContainer/Bonuses
@onready var experience = $PanelContainer/MarginContainer/VBoxContainer/Experience
@onready var drops = $PanelContainer/MarginContainer/VBoxContainer/AllDrops
@onready var animator = $AnimationPlayer
func _ready():
	CombatGlobals.exp_updated.connect(startProgress)
	animator.play('Show')

func startProgress(exp: int, required_exp: int):
	var tween = create_tween()
	experience.value = PlayerGlobals.CURRENT_EXP
	experience.max_value = required_exp
	tween.tween_property(experience, 'value', experience.value + exp, 1.0)

func _unhandled_input(event):
	if Input.is_action_just_pressed('ui_accept'):
		done.emit()
