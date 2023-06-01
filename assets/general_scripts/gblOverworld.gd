extends Node

var enemy_combatant_squad: Array[ResCombatant]
var player_can_move = true
var show_player_interaction = true

#********************************************************************************
# GENERAL UTILITY
#********************************************************************************
func getPlayer()-> PlayerScene:
	return get_tree().current_scene.get_node('Player')
	
#********************************************************************************
# OVERWORLD FUNCTIONS AND UTILITIES
#********************************************************************************
func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://assets/misc_scenes/DialogueBox.tscn")
	var SmallExampleBalloonScene = load("res://assets/misc_scenes/SmallDialogueBox.tscn")
	
	var is_small_window: bool = ProjectSettings.get_setting("display/window/size/viewport_width") < 400
	var balloon: Node = (SmallExampleBalloonScene if is_small_window else ExampleBalloonScene).instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, extra_game_states)
	
#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
func changeToCombat(inputted_enemy_combatants=null):
	var combat_scene: CombatScene = load("res://main_scenes/gameplay/gpscnCombatScene.tscn").instantiate()
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	if inputted_enemy_combatants == null:
		combat_scene.COMBATANTS.append_array(enemy_combatant_squad)
	else:
		combat_scene.COMBATANTS.append_array(inputted_enemy_combatants)
	enemy_combatant_squad = []
	
	getPlayer().process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene.add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	
func setEnemyCombatantSquad(entity_name: String):
	for combatant in getCombatantSquad(entity_name):
		enemy_combatant_squad.append(combatant.duplicate())
	
func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD
	
func restorePlayerView():
	getPlayer().process_mode = Node.PROCESS_MODE_ALWAYS
	getPlayer().player_camera.make_current()
	
