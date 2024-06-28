extends Node

var follow_array = []
var player_follower_count = 0
signal update_patroller_modes(mode:int)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

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
	getPlayer().can_move = enabled
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

func inMenu():
	return getPlayer().player_camera.has_node('uiMenu')

func setMenuFocus(container: Container):
	if container.get_child_count() > 0:
		container.get_child(0).grab_focus()

func setMenuFocusMode(control_item, mode: bool):
	if control_item is Button:
		if mode:
			control_item.focus_mode = Control.FOCUS_ALL
		else:
			control_item.focus_mode = Control.FOCUS_NONE
	elif control_item is Container:
		for child in control_item.get_children():
			if child is Button:
				if mode:
					child.focus_mode = Control.FOCUS_ALL
				else:
					child.focus_mode = Control.FOCUS_NONE

func insertTextureCode(texture: Texture)-> String:
	return '[img]%s[/img]' % texture.resource_path

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

func createItemButton(item: ResItem, value_modifier: float=0.0, show_count: bool=true)-> CustomButton:
	var button: CustomButton = preload("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.focused_entered_sound = preload("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	button.click_sound = preload("res://audio/sounds/421461__jaszunio15__click_46.ogg")
	button.custom_minimum_size.x = 28
	button.custom_minimum_size.y = 28
	button.expand_icon = true
	button.icon = item.ICON
	button.tooltip_text = item.NAME
	
	if item is ResStackItem and show_count:
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

func changeMap(map_name_path: String, coordinates: String='0,0,0',to_entity: String='',save:bool=false):
	get_tree().change_scene_to_file(map_name_path)
	await get_tree().create_timer(0.01).timeout
	
	if getCurrentMap().has_node('Player'):
		getCurrentMap().get_node('Player').loadData()
	var player = preload("res://scenes/entities/Player.tscn").instantiate()
	var coords = coordinates.split(',')
	getCurrentMap().add_child(player)
	if to_entity != '':
		player.global_position = getEntity(to_entity).global_position + Vector2(0, 20)
	else:
		player.global_position = Vector2(float(coords[0]),float(coords[1]))
	await get_tree().process_frame
	
	match int(coords[2]):
		0: player.direction = Vector2(0,1) # Down
		179: player.direction = Vector2(0,-1) # Up
		-90: player.direction = Vector2(1, 0) # Right
		90: player.direction = Vector2(-1,0) # Left
	
	if OverworldGlobals.getCurrentMapData().SAFE:
		OverworldGlobals.loadFollowers()
	if save:
		SaveLoadGlobals.saveGame()

func getCurrentMap()-> Node2D:
	return get_tree().current_scene

func getCurrentMapData()-> MapData:
	return get_tree().current_scene.get_node('MapDataComponent')

func isPlayerCheating()-> bool:
	return getPlayer().has_node('DebugComponent')

func showGameOver(end_sentence: String):
	setPlayerInput(false)
	getPlayer().set_collision_layer_value(5, false)
	getPlayer().set_collision_mask_value(5, false)
	getPlayer().set_collision_layer_value(1, false)
	getPlayer().set_collision_mask_value(1, false)
	playEntityAnimation('Player', 'Fall')
	update_patroller_modes.emit(0)
	await getEntity('Player').get_node('AnimationPlayer').animation_finished
	var menu: Control = load("res://scenes/user_interface/GameOver.tscn").instantiate()
	getPlayer().resetStates()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	getPlayer().player_camera.add_child(menu)
	menu.end_sentence.text = end_sentence

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
	if filename.begins_with('res://'):
		player.stream = load(filename)
	else:
		player.stream = load("res://audio/sounds/%s" % filename)
	player.volume_db = db
	if random_pitch:
		randomize()
		player.pitch_scale += randf_range(0.0, 0.25)
	add_child(player)
	player.play()

func addPatrollerPulse(location, radius:float, mode:int, trigger_others:bool=false):
	var pulse = preload("res://scenes/entities_disposable/PatrollerPulse.tscn").instantiate()
	pulse.radius = radius
	pulse.mode = mode
	pulse.trigger_others = trigger_others
	if location is Node2D:
		location.call_deferred('add_child', pulse)
	elif location is Vector2:
		pulse.global_position = location
		getCurrentMap().call_deferred('add_child', pulse)

#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
func changeToCombat(entity_name: String, combat_event_name: String=''):
	if get_parent().has_node('CombatScene'):
		await getCurrentMap().get_node('CombatScene').tree_exited
	if getCurrentMap().has_node('Balloon'):
		getCurrentMap().get_node('Balloon').queue_free()
		await getCurrentMap().get_node('Balloon').tree_exited
	
	if getCombatantSquad('Player').is_empty() or getCombatantSquadComponent('Player').isTeamDead():
		showGameOver('You could not defend yourself!')
		return
	
	var combat_scene: CombatScene = load("res://scenes/gameplay/CombatScene.tscn").instantiate()
	var combat_id = getCombatantSquadComponent(entity_name).UNIQUE_ID
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	for combatant in getCombatantSquad(entity_name):
		if combatant == null: continue
		var duped_combatant = combatant.duplicate()
		for effect in getCombatantSquadComponent(entity_name).afflicted_status_effects:
			duped_combatant.LINGERING_STATUS_EFFECTS.append(effect)
		combat_scene.COMBATANTS.append(duped_combatant)
	if combat_event_name != '':
		combat_scene.combat_event = load("res://resources/combat/events/%s.tres" % combat_event_name)
	if combat_id != null:
		combat_scene.unique_id = combat_id
	combat_scene.battle_music_path = CombatGlobals.FACTION_MUSIC[getCombatantSquadComponent(entity_name).getMusic()].pick_random()
	var battle_transition = preload("res://scenes/miscellaneous/BattleTransition.tscn").instantiate()
	getPlayer().player_camera.add_child(battle_transition)
	battle_transition.get_node('AnimationPlayer').play('In')
	await battle_transition.get_node('AnimationPlayer').animation_finished
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	get_parent().add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	if getEntity(entity_name).has_node('CombatDialogue'):
		combat_scene.combat_dialogue = getComponent(entity_name, 'CombatDialogue')
	getCurrentMap().hide()
	await combat_scene.combat_done
	var combat_results = combat_scene.combat_result
	getPlayer().player_camera.make_current()
	get_tree().paused = false
	battle_transition.get_node('AnimationPlayer').play('Out')
	getCurrentMap().show()
#	if hasCombatDialogue(entity_name):
#		setPlayerInput(false)
	await battle_transition.get_node('AnimationPlayer').animation_finished
	battle_transition.queue_free()
	getPlayer().resetStates()
	if hasCombatDialogue(entity_name) and combat_results == 1:
		showDialogueBox(getComponent(entity_name, 'CombatDialogue').dialogue_resource, 'win_aftermath')
		await getCurrentMap().get_node('Balloon').tree_exited
		setPlayerInput(true)
	elif combat_results != 0:
		setPlayerInput(true)

func inCombat()-> bool:
	return get_parent().has_node('CombatScene')

func hasCombatDialogue(entity_name: String)-> bool:
	return getEntity(entity_name).has_node('CombatDialogue') and getComponent(entity_name, 'CombatDialogue').enabled

func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD

func getCombatantSquadComponent(entity_name: String)-> CombatantSquad:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent')

func afflictCombatantSquad(entity_name: String, status_effect_name: String):
	getCombatantSquadComponent(entity_name).afflicted_status_effects.append(status_effect_name)

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
