extends Node

var showing_menu = false
var enemy_combatant_squad: Array[ResCombatant]
var player_can_move = true
var show_player_interaction = true

signal move_entity(target_position)
signal alert_patrollers()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	for member in getCombatantSquad('Player'):
		if !member.initialized:
			member.initializeCombatant()
			member.SCENE.free()
	
#********************************************************************************
# SIGNALS
#********************************************************************************
func moveEntity(entity_body_name: String, move_sequence: String):
	move_entity.emit(entity_body_name, move_sequence)
	await getEntity(entity_body_name).get_node('NPCMovementComponent').movement_finished
	
func alertPatrollers():
	alert_patrollers.emit()
	
#********************************************************************************
# GENERAL UTILITY
#********************************************************************************
func getPlayer()-> PlayerScene:
	return get_tree().current_scene.get_node('Player')
	
func getEntity(entity_name: String)-> PlayerScene:
	return get_tree().current_scene.get_node(entity_name)
	
func showMenu(path: String):
	
	var main_menu: Control = load(path).instantiate()
	
	if !showing_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		getPlayer().player_camera.add_child(main_menu)
		player_can_move = false
		show_player_interaction = false
		showing_menu = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		main_menu.queue_free()
		getPlayer().player_camera.get_child(0).queue_free()
		player_can_move = true
		show_player_interaction = true
		showing_menu = false

func getCurrentMap()-> Node2D:
	return get_tree().current_scene
	
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
	var temp = []
	var combat_scene: CombatScene = load("res://main_scenes/gameplay/gpscnCombatScene.tscn").instantiate()
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	if inputted_enemy_combatants == null:
		combat_scene.COMBATANTS.append_array(enemy_combatant_squad)
	else:
		for combatant in inputted_enemy_combatants:
			temp.append(combatant.duplicate())
		combat_scene.COMBATANTS.append_array(temp)
	enemy_combatant_squad = []
	
	get_tree().current_scene.add_child(combat_scene)
	pauseAllExcept(combat_scene)
	combat_scene.combat_camera.make_current()
	
func setEnemyCombatantSquad(entity_name: String):
	for combatant in getCombatantSquad(entity_name):
		enemy_combatant_squad.append(combatant.duplicate())
	
func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD
	
func pauseAllExcept(node):
	for child in get_tree().current_scene.get_children():
		if child == node: continue
		child.process_mode = Node.PROCESS_MODE_DISABLED
	
func restorePlayerView():
	for child in get_tree().current_scene.get_children():
		if !child.can_process():
			child.process_mode = Node.PROCESS_MODE_ALWAYS
	
	getPlayer().player_camera.make_current()
	
