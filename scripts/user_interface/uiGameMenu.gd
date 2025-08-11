extends Control

@onready var experience_bar = $Experience
@onready var experience_current = $Experience/Label
@onready var level = $Experience/Level
@onready var general_party_bars = $GeneralBars

func _ready():
	experience_bar.max_value = PlayerGlobals.getRequiredExp()
	experience_bar.value = PlayerGlobals.current_exp
	experience_current.text = '%s / %s' % [PlayerGlobals.current_exp, PlayerGlobals.getRequiredExp()]
	level.text =  str(PlayerGlobals.team_level)
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		var bar = load("res://scenes/user_interface/GeneralCombatantStatus.tscn").instantiate()
		general_party_bars.add_child(bar)
		bar.combatant = combatant
