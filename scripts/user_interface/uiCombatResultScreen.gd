extends Control
class_name CombatResults

signal done

@onready var title = $PanelContainer/MarginContainer/VBoxContainer/ResultsTitle
@onready var round_label = $PanelContainer/MarginContainer/VBoxContainer/Rounds/Criteria
@onready var player_turns_label = $PanelContainer/MarginContainer/VBoxContainer/PlayerTurns/Criteria
@onready var enemy_turns_label = $PanelContainer/MarginContainer/VBoxContainer/EnemyTurns/Criteria
@onready var round_count = $PanelContainer/MarginContainer/VBoxContainer/Rounds/Value
@onready var morale_label = $PanelContainer/MarginContainer/VBoxContainer/EnemyTurns2/Criteria
@onready var player_turns = $PanelContainer/MarginContainer/VBoxContainer/PlayerTurns/Value
@onready var enemy_turns = $PanelContainer/MarginContainer/VBoxContainer/EnemyTurns/Value
@onready var morale_gained = $PanelContainer/MarginContainer/VBoxContainer/EnemyTurns2/Value
@onready var all_loot_label = $PanelContainer/MarginContainer/VBoxContainer/ResultsTitle3
@onready var loot_label = $PanelContainer/MarginContainer/VBoxContainer/ResultsTitle4
@onready var loot_icons = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer
@onready var animator = $AnimationPlayer
@onready var combat_scene = CombatGlobals.getCombatScene()

var rounds = 0
var turns_player = 0
var turns_enemy = 0
var morale = PlayerGlobals.current_exp
var done_showing = false

func _ready():
	var tween_rounds = combat_scene.create_tween()
	var tween_player = combat_scene.create_tween()
	var tween_enemy = combat_scene.create_tween()
	var tween_morale = combat_scene.create_tween()
	animator.play("Show")
	tween_rounds.tween_method(setRounds, rounds, combat_scene.round_count, 0.25)
	tween_player.tween_method(setPlayerTurns, turns_player, combat_scene.player_turn_count, 0.25)
	tween_enemy.tween_method(setEnemyTurns, turns_enemy, combat_scene.enemy_turn_count, 0.25)
	showLoot()
	await tween_morale.finished
	if combat_scene.round_count <= 2:
		changeText(round_label, 'Fast Finish!')
		bonusTween(round_label)
		bonusTween(round_count)
		OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
		await get_tree().create_timer(0.25).timeout
	if combat_scene.enemy_turn_count < combat_scene.getCombatantGroup('enemies').size():
		changeText(enemy_turns_label, 'Ruthless Finish!')
		bonusTween(enemy_turns_label)
		bonusTween(enemy_turns)
		OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
		await get_tree().create_timer(0.25).timeout
	if combat_scene.player_turn_count < combat_scene.getCombatantGroup('team').size():
		changeText(player_turns_label, 'Stragetic Finish!')
		bonusTween(player_turns_label)
		bonusTween(player_turns)
		OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
		await get_tree().create_timer(0.25).timeout
	if morale > PlayerGlobals.getRequiredExp():
		if PlayerGlobals.max_team_level <= PlayerGlobals.team_level:
			changeText(morale_label, 'Maxed!')
		else:
			changeText(morale_label, 'Level Up!')
		bonusTween(morale_label)
		bonusTween(morale_gained)
		OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
		await get_tree().create_timer(0.25).timeout
	done_showing = true

func setMorale(value):
	morale = value

func setPlayerTurns(value):
	turns_player = value

func setEnemyTurns(value):
	turns_enemy = value

func setRounds(value):
	rounds = value

func _process(_delta):
	round_count.text = str(rounds)
	player_turns.text = str(turns_player)
	enemy_turns.text = str(turns_enemy)
	morale_gained.text = '%s / %s' % [str(floor(morale)), str(PlayerGlobals.getRequiredExp())]

func _unhandled_input(_event):
	if Input.is_action_just_released('ui_accept') and done_showing:
		done.emit()

func bonusTween(label: Label):
	var tween = combat_scene.create_tween()
	tween.tween_property(label, 'modulate', Color(Color.YELLOW), 0.25)
	tween.tween_property(label, 'modulate', Color(Color.WHITE), 1.5)

func changeText(label: Label, new_text: String):
	label.visible_ratio = 0
	label.text = new_text
	create_tween().tween_property(label, 'visible_ratio', 1, 0.25)

func hideLoot():
	morale_label.hide()
	morale_gained.hide()
	loot_icons.hide()
	loot_label.hide()
	all_loot_label.hide()

func showLoot():
#	FIX LATER!
#	var bank = OverworldGlobals.getCurrentMap().REWARD_BANK['loot']
#	for drop in bank.keys():
#		var icon: TextureRect = TextureRect.new()
#		icon.texture = drop.icon.duplicate()
#		icon.tooltip_text = drop.name
#		var count_label = Label.new()
#		count_label.text = str(OverworldGlobals.getCurrentMap().REWARD_BANK['loot'][drop])
#		count_label.theme = preload("res://design/OutlinedLabel.tres")
#		icon.add_child(count_label)
#		if combat_scene.drops.has(drop):
#			var tween = create_tween()
#			var tween_b = create_tween()
#			loot_icons.add_child(icon)
#			tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
#			tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.5)
#			tween_b.tween_property(icon, 'self_modulate', Color.YELLOW, 0.25)
#			tween_b.tween_property(icon, 'self_modulate', Color.WHITE, 1.5)
#			OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg", 4.0)
#		else:
#			loot_icons.add_child(icon)
		await get_tree().create_timer(0.15).timeout
