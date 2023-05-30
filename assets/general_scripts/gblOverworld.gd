extends Node

var player_squad: Array[ResCombatant]
var combatant_squad: Array[ResCombatant]
var player_can_move = true
var show_player_interaction = true

func changeToCombat():
	var combat_scene: CombatScene = load("res://main_scenes/gameplay/gpscnCombatScene.tscn").instantiate()
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	combat_scene.COMBATANTS.append_array(combatant_squad)
	combatant_squad = []
	
	getPlayer().process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene.add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	
func restorePlayerView():
	getPlayer().process_mode = Node.PROCESS_MODE_ALWAYS
	getPlayer().player_camera.make_current()
	
func setCombatantSquad(entity_name: String):
	for combatant in getCombatantSquad(entity_name):
		combatant_squad.append(combatant.duplicate())
	
func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD
	
func getPlayer()-> PlayerScene:
	return get_tree().current_scene.get_node('Player')
	
func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://assets/misc_scenes/DialogueBox.tscn")
	var SmallExampleBalloonScene = load("res://assets/misc_scenes/SmallDialogueBox.tscn")
	
	var is_small_window: bool = ProjectSettings.get_setting("display/window/size/viewport_width") < 400
	var balloon: Node = (SmallExampleBalloonScene if is_small_window else ExampleBalloonScene).instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, extra_game_states)
	
