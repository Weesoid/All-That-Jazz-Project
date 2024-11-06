extends Control
class_name CombatResults

signal done

@onready var title = $PanelContainer/MarginContainer/VBoxContainer/ResultsTitle
@onready var round_count = $PanelContainer/MarginContainer/VBoxContainer/Rounds/Value
@onready var player_turns = $PanelContainer/MarginContainer/VBoxContainer/PlayerTurns/Value
@onready var enemy_turns = $PanelContainer/MarginContainer/VBoxContainer/EnemyTurns/Value
@onready var morale_gained = $PanelContainer/MarginContainer/VBoxContainer/EnemyTurns2/Value
@onready var loot_icons = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer
@onready var animator = $AnimationPlayer
@onready var combat_scene = CombatGlobals.getCombatScene()

func _ready():
	CombatGlobals.exp_updated.connect(startProgress)
	animator.play("Show")
	OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")

func startProgress(xp: int, required_exp: int):
	CombatGlobals.exp_updated.disconnect(startProgress)
#	experience.value = PlayerGlobals.CURRENT_EXP
#	experience.max_value = required_exp
#	create_tween().tween_property(experience, 'value', experience.value + xp, 1.0)

func writeDrops(item_drops: Dictionary):
	var text = ''
	for item in item_drops.keys():
		text += '%s x%s\n' % [item.NAME, item_drops[item]]
	
#	drops.text = text
#	create_tween().tween_property(drops, 'visible_ratio', 1, 1.25)

func setBonuses(bonus: String):
	pass
#	bonuses.text = bonus
#	create_tween().tween_property(bonuses, 'visible_ratio', 1, 1.0)

func _unhandled_input(_event):
	if Input.is_action_just_released('ui_accept'):
		done.emit()
