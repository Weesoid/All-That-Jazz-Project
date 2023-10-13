extends Node

var showing_menu = false
var enemy_combatant_squad: Array[ResCombatant]
var player_can_move = true
var show_player_interaction = true
var follow_array = []
var player_follower_count = 0

signal move_entity(target_position)
signal alert_patrollers()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	CombatGlobals.combat_conclusion_dialogue.connect(showCombatAftermathDialogue)

func initializePlayerParty():
	if getCombatantSquad('Player').is_empty():
		return
	
	for member in getCombatantSquad('Player'):
		if !member.initialized:
			member.initializeCombatant()
			member.SCENE.free()
		loadFollower(member)
	
	follow_array.resize(100)

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
	main_menu.name = 'uiMenu'
	
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
	getPlayer().player_camera.get_node('uiMenu').queue_free()
	player_can_move = true
	show_player_interaction = true
	showing_menu = false

func showShop(shopkeeper_name: String, buy_mult=1.0, sell_mult=0.5):
	var main_menu: Control = load("res://scenes/user_interface/Shop.tscn").instantiate()
	main_menu.wares_array = getComponent(shopkeeper_name, 'ShopWares').SHOP_WARES
	main_menu.buy_modifier = buy_mult
	main_menu.sell_modifier = sell_mult
	main_menu.name = 'uiMenu'
	
	if !showing_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		getPlayer().player_camera.add_child(main_menu)
		player_can_move = false
		show_player_interaction = false
		showing_menu = true
	else:
		closeMenu(main_menu)

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
	if get_parent().has_node('CombatScene'):
		get_parent().get_node('CombatScene').add_child(balloon)
	else:
		get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, extra_game_states)

func showCombatAftermathDialogue(resource: DialogueResource, result, extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://scenes/miscellaneous/DialogueBox.tscn")
	var SmallExampleBalloonScene = load("res://scenes/miscellaneous/SmallDialogueBox.tscn")
	
	var is_small_window: bool = ProjectSettings.get_setting("display/window/size/viewport_width") < 400
	var balloon: Node = (SmallExampleBalloonScene if is_small_window else ExampleBalloonScene).instantiate()
	get_tree().current_scene.add_child(balloon)
	if result == 0:
		print('Lose!')
		balloon.start(resource, 'lose', extra_game_states)
	elif result == 1:
		print('Won!')
		balloon.start(resource, 'win', extra_game_states)

func loadFollower(combatant: ResPlayerCombatant):
	if PlayerGlobals.hasFollower(combatant) or combatant.FOLLOWER_PACKED_SCENE == null:
		return
	
	var follower_scene
	follower_scene = combatant.FOLLOWER_PACKED_SCENE.instantiate()
	follower_scene.host_combatant = combatant
	PlayerGlobals.addFollower(follower_scene)
	follower_scene.global_position = getPlayer().global_position
	getCurrentMap().add_child(follower_scene)

#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
func changeToCombat(entity_name: String, combat_dialogue_name: String='', aftermath_dialogue_name: String = ''):
	print('start')
	var combat_scene: CombatScene = load("res://scenes/gameplay/CombatScene.tscn").instantiate()
	var combat_id = getCombatantSquadComponent(entity_name).UNIQUE_ID
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	
	for combatant in getCombatantSquad(entity_name):
		combat_scene.COMBATANTS.append(combatant.duplicate())
	if combat_id != null:
		combat_scene.unique_id = combat_id
	
	if !combat_dialogue_name.is_empty():
		combat_scene.combat_dialogue = load("res://resources/combat_dialogue/%s.tres" % [combat_dialogue_name])
	if !aftermath_dialogue_name.is_empty():
		combat_scene.conclusion_dialogue = load("res://resources/dialogue/%s.dialogue" % [aftermath_dialogue_name])
	
	get_tree().paused = true
	get_parent().add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	await combat_scene.combat_done
	getPlayer().player_camera.make_current()
	get_tree().paused = false

func setEnemyCombatantSquad(entity_name: String):
	for combatant in getCombatantSquad(entity_name):
		enemy_combatant_squad.append(combatant.duplicate())

func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD

func getCombatantSquadComponent(entity_name: String):
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent')

func getComponent(entity_name: String, component_name: String):
	return get_tree().current_scene.get_node(entity_name).get_node(component_name)

func isPlayerSquadDead():
	for combatant in getCombatantSquad('Player'):
		if !combatant.isDead():
			return false
	
	return true

func restorePlayerView():
	getPlayer().player_camera.make_current()
	get_tree().paused = false
	print('Restored!')
	
