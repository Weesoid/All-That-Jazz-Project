extends Node

var follow_array = []
var player_follower_count = 0

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
	
	if OverworldGlobals.getCurrentMapData().SAFE:
		loadFollowers()
	
	follow_array.resize(100)

func setPlayerInput(enabled:bool):
	getPlayer().set_process_unhandled_input(enabled)

func inDialogue() -> bool:
	return getCurrentMap().has_node('Balloon')

#********************************************************************************
# SIGNALS
#********************************************************************************
func moveEntity(entity_body_name: String, move_to, offset=Vector2(0,0), speed=35.0, animate_direction=true, wait=true):
	if getEntity(entity_body_name).has_node('ScriptedMovementComponent'):
		await getEntity(entity_body_name).get_node('ScriptedMovementComponent').tree_exited
	
	PlayerGlobals.setFollowersMotion(false)
	getEntity(entity_body_name).add_child(preload("res://scenes/components/ScriptedMovement.tscn").instantiate())
	getEntity(entity_body_name).get_node('ScriptedMovementComponent').ANIMATE_DIRECTION = animate_direction
	getEntity(entity_body_name).get_node('ScriptedMovementComponent').MOVE_SPEED = speed
	
	if move_to is Vector2:
		getEntity(entity_body_name).get_node('ScriptedMovementComponent').TARGET_POSITIONS.append(move_to + offset)
	elif move_to is String and move_to.contains('>'):
		getEntity(entity_body_name).get_node('ScriptedMovementComponent').moveBody(move_to)
	elif move_to is String:
		getEntity(entity_body_name).get_node('ScriptedMovementComponent').TARGET_POSITIONS.append(getEntity(move_to).global_position + offset)
	else:
		print('Invalid move_to parameter.')
	
	if wait:
		await getEntity(entity_body_name).get_node('ScriptedMovementComponent').movement_finished
	PlayerGlobals.setFollowersMotion(true)

func alertPatrollers():
	alert_patrollers.emit()
	
#********************************************************************************
# GENERAL UTILITY
#********************************************************************************
func getPlayer()-> PlayerScene:
	return get_tree().current_scene.get_node('Player')

func getEntity(entity_name: String):
	return get_tree().current_scene.get_node(entity_name)

func playEntityAnimation(entity_name: String, animation_name: String, wait=true):
	getEntity(entity_name).get_node('AnimationPlayer').play(animation_name)
	if wait:
		await getEntity(entity_name).get_node('AnimationPlayer').animation_finished

func changeEntityVisibility(entity_name: String, visibility:bool):
	if get_tree().current_scene.get_node(entity_name) is PlayerScene:
		getPlayer().sprite.visible = visibility
	else:
		get_tree().current_scene.get_node(entity_name).visible = visibility

func teleportEntity(entity_name, teleport_to, offset=Vector2(0, 0)):
	if teleport_to is Vector2:
		getEntity(entity_name).global_position = teleport_to + offset
	elif teleport_to is String:
		getEntity(entity_name).global_position = getEntity(teleport_to).global_position + offset

func showMenu(path: String):
	var main_menu: Control = load(path).instantiate()
	main_menu.name = 'uiMenu'
	getPlayer().resetStates()
	if !inMenu():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		getPlayer().player_camera.add_child(main_menu)
		setPlayerInput(false)
	else:
		closeMenu(main_menu)

func closeMenu(menu: Control):
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	menu.queue_free()
	getPlayer().player_camera.get_node('uiMenu').queue_free()
	setPlayerInput(true)
	#show_player_interaction = true

func inMenu():
	return getPlayer().player_camera.has_node('uiMenu')

func showShop(shopkeeper_name: String, buy_mult=1.0, sell_mult=0.5, entry_description=''):
	var main_menu: Control = load("res://scenes/user_interface/Shop.tscn").instantiate()
	main_menu.wares_array = getComponent(shopkeeper_name, 'ShopWares').SHOP_WARES
	main_menu.buy_modifier = buy_mult
	main_menu.sell_modifier = sell_mult
	main_menu.open_description = entry_description
	main_menu.name = 'uiMenu'
	
	if !inMenu():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		getPlayer().player_camera.add_child(main_menu)
		setPlayerInput(false)
		#show_player_interaction = false
	else:
		closeMenu(main_menu)

func createCustomButton(theme: Theme = preload("res://design/DefaultTheme.tres"))-> CustomButton:
	var button = preload("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.theme = theme
	return button

func createItemButton(item: ResItem, value_modifier=0.0)-> CustomButton:
	var button = preload("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.custom_minimum_size.x = 28
	button.custom_minimum_size.y = 28
	button.expand_icon = true
	button.icon = item.ICON
	button.tooltip_text = item.NAME
	
	if item is ResStackItem:
		var label = Label.new()
		label.text = str(item.STACK)
		label.theme = preload("res://design/OutlinedLabel.tres")
		button.add_child(label)
	
	if value_modifier != 0.0:
		var label = Label.new()
		if item.VALUE * value_modifier <= 0:
			label.text = 'Free'
			label.add_theme_font_size_override('font_size', 6)
		else:
			label.text = str(int(item.VALUE * value_modifier))
		label.theme = preload("res://design/OutlinedLabel.tres")
		label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		label.set_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		button.add_child(label)
	
	if item.MANDATORY:
		button.theme = preload("res://design/ItemButtonsMandatory.tres")
	else:
		button.theme = preload("res://design/ItemButtons.tres")
	
	return button

func showPlayerPrompt(message: String, time=5.0, audio_file = ''):
	OverworldGlobals.getPlayer().prompt.showPrompt(message, time, audio_file)

func changeMap(map_name: String):
	get_tree().change_scene_to_file("res://scenes/maps/%s.tscn" % map_name)

func getCurrentMap()-> Node2D:
	return get_tree().current_scene

func getCurrentMapData()-> MapData:
	return get_tree().current_scene.get_node('MapDataComponent')

#********************************************************************************
# OVERWORLD FUNCTIONS AND UTILITIES
#********************************************************************************
func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://scenes/user_interface/DialogueBox.tscn")
	var balloon: Node = ExampleBalloonScene.instantiate()
	
	if get_parent().has_node('CombatScene'):
		get_parent().get_node('CombatScene').add_child(balloon)
	else:
		get_tree().current_scene.add_child(balloon)
	balloon.start(resource, title, extra_game_states)

func showCombatAftermathDialogue(resource: DialogueResource, result, extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://scenes/miscellaneous/DialogueBox.tscn")
	var balloon: Node = ExampleBalloonScene.instantiate()
	
	get_tree().current_scene.add_child(balloon)
	if result == 0:

		balloon.start(resource, 'lose', extra_game_states)
	elif result == 1:

		balloon.start(resource, 'win', extra_game_states)

# REFACTOR
func loadFollowers():
	for follower in PlayerGlobals.FOLLOWERS:
		if follower != null: follower.queue_free()
	PlayerGlobals.FOLLOWERS.clear()
	
	for combatant in PlayerGlobals.TEAM:
		if combatant.active and combatant.FOLLOWER_PACKED_SCENE != null:
			var follower_scene = combatant.FOLLOWER_PACKED_SCENE.instantiate()
			follower_scene.host_combatant = combatant
			PlayerGlobals.addFollower(follower_scene)
			follower_scene.global_position = getPlayer().global_position
			getCurrentMap().add_child.call_deferred(follower_scene)

func playSound(filename: String, db=0.0, pitch = 1, random_pitch=false):
	var player = AudioStreamPlayer.new()
	player.connect("finished", player.queue_free)
	player.pitch_scale = pitch
	player.stream = load("res://audio/sounds/%s" % filename)
	player.volume_db = db
	if random_pitch:
		randomize()
		player.pitch_scale += randf_range(0.0, 0.25)
	add_child(player)
	player.play()

#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
func changeToCombat(entity_name: String, combat_dialogue_name: String='', aftermath_dialogue_name: String = '', initial_status_effect_enemy: String = '', initial_status_effect_player: String = '', combat_event_name: String=''):
	if get_parent().has_node('CombatantSquadComponent'):
		await get_parent().get_node('CombatantSquadComponent').tree_exited
	
	var combat_scene: CombatScene = load("res://scenes/gameplay/CombatScene.tscn").instantiate()
	var combat_id = getCombatantSquadComponent(entity_name).UNIQUE_ID
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	
	for combatant in getCombatantSquad(entity_name):
		combat_scene.COMBATANTS.append(combatant.duplicate())
	
	combat_scene.initial_status_effect_enemy = initial_status_effect_enemy
	combat_scene.initial_status_effect_player = initial_status_effect_player
	if combat_event_name != '':
		combat_scene.combat_event = load("res://resources/combat/events/%s.tres" % combat_event_name)
	
	if combat_id != null:
		combat_scene.unique_id = combat_id
	if !combat_dialogue_name.is_empty():
		combat_scene.combat_dialogue = load("res://resources/combat_dialogue/%s.tres" % [combat_dialogue_name])
	if !aftermath_dialogue_name.is_empty():
		combat_scene.conclusion_dialogue = load("res://resources/dialogue/%s.dialogue" % [aftermath_dialogue_name])
	
	var battle_transition = preload("res://scenes/miscellaneous/BattleTransition.tscn").instantiate()
	getPlayer().player_camera.add_child(battle_transition)
	battle_transition.get_node('AnimationPlayer').play('In')
	await battle_transition.get_node('AnimationPlayer').animation_finished
	
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	get_parent().add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	
	getCurrentMap().hide()
	await combat_scene.combat_done
	getPlayer().player_camera.make_current()
	get_tree().paused = false
	battle_transition.get_node('AnimationPlayer').play('Out')
	getCurrentMap().show()
	await battle_transition.get_node('AnimationPlayer').animation_finished
	battle_transition.queue_free()
	getPlayer().resetStates()

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
