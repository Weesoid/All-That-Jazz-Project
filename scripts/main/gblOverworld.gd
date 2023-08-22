extends Node

var showing_menu = false
var enemy_combatant_squad: Array[ResCombatant]
var player_can_move = true
var show_player_interaction = true
var follow_array = []


signal move_entity(target_position)
signal alert_patrollers()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	for member in getCombatantSquad('Player'):
		if !member.initialized:
			member.initializeCombatant()
			member.SCENE.free()

	follow_array.resize(100)
	loadFollowers()

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
		closeMenu(main_menu)

func closeMenu(menu: Control):
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	menu.queue_free()
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
	var ExampleBalloonScene = load("res://scenes/miscellaneous/DialogueBox.tscn")
	var SmallExampleBalloonScene = load("res://scenes/miscellaneous/SmallDialogueBox.tscn")
	
	var is_small_window: bool = ProjectSettings.get_setting("display/window/size/viewport_width") < 400
	var balloon: Node = (SmallExampleBalloonScene if is_small_window else ExampleBalloonScene).instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, extra_game_states)

func loadFollowers():
	var index = 20
	for follower in getCombatantSquad('Player'):
		follower.FOLLOWER_SCENE.FOLLOW_LOCATION = index
		getCurrentMap().add_child(follower.FOLLOWER_SCENE)
		index += 20
	

#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
func changeToCombat(entity_name: String):
	var combat_scene: CombatScene = load("res://scenes/gameplay/CombatScene.tscn").instantiate()
	var combat_id = getCombatantSquadComponent(entity_name).UNIQUE_ID
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	for combatant in getCombatantSquad(entity_name):
		combat_scene.COMBATANTS.append(combatant.duplicate())
	if combat_id != null:
		combat_scene.unique_id = combat_id
	
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	get_parent().add_child(combat_scene)
	combat_scene.combat_camera.make_current()

func setEnemyCombatantSquad(entity_name: String):
	for combatant in getCombatantSquad(entity_name):
		enemy_combatant_squad.append(combatant.duplicate())

func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD

func getCombatantSquadComponent(entity_name: String):
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent')

func restorePlayerView():
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	getPlayer().player_camera.make_current() 
	
