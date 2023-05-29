extends Node

var player_can_move = true
var show_player_interaction = true

func changeToCombat():
	# Load combatants in array as param
	var combatantA: ResCombatant = load("res://assets/combatants_resources/cbEPrototypeA.tres").duplicate()
	var combatantB: ResCombatant = load("res://assets/combatants_resources/cbEPrototypeB.tres").duplicate()
	var combatantC: ResCombatant = load("res://assets/combatants_resources/cbPPrototypeA.tres").duplicate()
	var combatantD: ResCombatant = load("res://assets/combatants_resources/cbPPrototypeB.tres").duplicate()
	var my_array: Array[ResCombatant] = [combatantA, combatantB, combatantC, combatantD]
	
	var combat_scene: CombatScene = preload("res://main_scenes/gameplay/gpscnCombatScene.tscn").instantiate()
	combat_scene.COMBATANTS = my_array
	
	#var player: PlayerScene = get_tree().current_scene.get_node('Player')
	getPlayer().process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene.add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	
func restorePlayerView():
	getPlayer().process_mode = Node.PROCESS_MODE_ALWAYS
	getPlayer().player_camera.make_current()
	
func getPlayer()-> PlayerScene:
	return get_tree().current_scene.get_node('Player')
	
func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://assets/misc_scenes/DialogueBox.tscn")
	var SmallExampleBalloonScene = load("res://assets/misc_scenes/SmallDialogueBox.tscn")

	var is_small_window: bool = ProjectSettings.get_setting("display/window/size/viewport_width") < 400
	var balloon: Node = (SmallExampleBalloonScene if is_small_window else ExampleBalloonScene).instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, extra_game_states)
	
