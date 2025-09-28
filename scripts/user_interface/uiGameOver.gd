extends Control

@onready var buttons= $VBoxContainer
@onready var end_sentence = $EndSentence
@onready var animator = $AnimationPlayer
#@onready var saves = $Saves
@onready var penalty = $Penalty
var sounds = [
	"res://audio/sounds/488375__wobesound__deathgameoverv2.ogg",
	"res://audio/sounds/488376__wobesound__deathgameoverv1.ogg"
]
var current_currency = PlayerGlobals.currency

func _ready():
	randomize()
	#OverworldGlobals.shakeCamera(20,20)
	var saved_game: SavedGame = load("res://saves/%s.tres" % PlayerGlobals.save_name)
	var random_penalty = randf_range(0.2, 0.3)
	var reduced_currency = PlayerGlobals.currency - int(random_penalty * PlayerGlobals.currency)
	var reduced_exp = PlayerGlobals.current_exp - int(random_penalty * PlayerGlobals.getRequiredExp())
	penalty.text = '-'+str(int(random_penalty*100))+'% Slips and Morale.'
	if reduced_currency < 0: 
		reduced_currency = 0
	if reduced_exp < 0: 
		reduced_exp = 0
	for data in saved_game.save_data:
		if data is PlayerSaveData:
			data.currency = reduced_currency
			data.current_exp = reduced_exp
			PlayerGlobals.currency = reduced_currency
			PlayerGlobals.current_exp = reduced_exp
			break
	ResourceSaver.save(saved_game, "res://saves/%s.tres" % PlayerGlobals.save_name)
	
	animator.play('Show')
	OverworldGlobals.playSound("res://audio/sounds/252198__pepingrillin__rocket_impact.ogg")
	OverworldGlobals.setMouseController(true)
	OverworldGlobals.setMenuFocus(buttons)

func _on_yes_pressed():
	buttons.hide()
	penalty.hide()
	SaveLoadGlobals.loadSaveFile()

func _on_no_pressed():
	get_tree().change_scene_to_file("res://scenes/user_interface/StartMenu.tscn")
