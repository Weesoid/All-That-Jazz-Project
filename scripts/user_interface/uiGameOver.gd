extends Control

@onready var buttons= $VBoxContainer
@onready var end_sentence = $EndSentence
@onready var animator = $AnimationPlayer
@onready var saves = $Saves
@onready var experience = $VBoxContainer2/HFlowContainer/ProgressBar
@onready var cash = $VBoxContainer2/HSplitContainer/Cash
var current_currency = PlayerGlobals.CURRENCY

func _ready():
	randomize()
	PlayerGlobals.healCombatants()
	var reduced_exp = randf_range(-0.2, -0.1) * PlayerGlobals.getRequiredExp()
	var reduced_currency = randf_range(-0.2, -0.5) * PlayerGlobals.CURRENCY
	PlayerGlobals.addExperience(reduced_exp)
	PlayerGlobals.addCurrency(reduced_currency)
	SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME, false)
	
	var tween = create_tween()
	var tween_b = create_tween().set_trans(Tween.TRANS_EXPO)
	animator.play("Flash_Red")
	experience.max_value = PlayerGlobals.getRequiredExp()
	experience.value = PlayerGlobals.CURRENT_EXP
	tween.tween_property(experience, 'value', ceil(experience.value+reduced_exp),0.5)
	tween_b.tween_method(set_number, current_currency, PlayerGlobals.CURRENCY, 1.0)
	await tween_b.finished
	animator.play('Show')
	await animator.animation_finished
	OverworldGlobals.setMenuFocus(buttons)

func _on_yes_pressed():
	if FileAccess.file_exists("res://saves/%s.tres" % PlayerGlobals.SAVE_NAME):
		var saved_game: SavedGame = load("res://saves/%s.tres" % PlayerGlobals.SAVE_NAME)
		OverworldGlobals.changeMap(saved_game.current_map_path, '0,0,0', 'SavePoint', true, true)
		PlayerGlobals.healCombatants()
		PlayerGlobals.overworld_stats['stamina'] = 100.0
		OverworldGlobals.getPlayer().setUIVisibility(true)

func _on_no_pressed():
	get_tree().quit()

func _process(_delta):
	if PlayerGlobals.CURRENCY > 0:
		cash.text = str(int(current_currency))
	else:
		cash.text = 'BROKE!'

func set_number(value):
	current_currency = value
