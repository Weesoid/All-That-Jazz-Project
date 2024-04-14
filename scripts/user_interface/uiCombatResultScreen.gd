extends Control
class_name CombatResults

signal done

@onready var title = $PanelContainer/MarginContainer/VBoxContainer/ResultsTitle
@onready var bonuses = $PanelContainer/MarginContainer/VBoxContainer/Bonuses
@onready var experience = $PanelContainer/MarginContainer/VBoxContainer/Experience
@onready var drops = $PanelContainer/MarginContainer/VBoxContainer/AllDrops
@onready var animator = $AnimationPlayer

func _ready():
	CombatGlobals.exp_updated.connect(startProgress)
	animator.play('Show')

func startProgress(exp: int, required_exp: int):
	experience.value = PlayerGlobals.CURRENT_EXP
	experience.max_value = required_exp
	create_tween().tween_property(experience, 'value', experience.value + exp, 1.0)

func writeDrops(item_drops: Dictionary):
	var text = ''
	for item in item_drops.keys():
		text += '%s x%s\n' % [item.NAME, item_drops[item]]
	
	drops.text = text
	create_tween().tween_property(drops, 'visible_ratio', 1, 1.25)

func setBonuses(bonus: String):
	bonuses.text = bonus
	create_tween().tween_property(bonuses, 'visible_ratio', 1, 1.0)

func _unhandled_input(event):
	if Input.is_action_just_pressed('ui_accept'):
		done.emit()
