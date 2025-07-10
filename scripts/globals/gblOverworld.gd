extends Node

enum PlayerType {
	WILLIS,
	ARCHIE
}
var entering_combat:bool=false
var player_type: PlayerType = PlayerType.ARCHIE
var delayed_rewards: Dictionary
var player_follower_count = 0

signal update_patroller_modes(mode:int)
signal patroller_destroyed
signal party_damaged
signal combat_enetered
signal combat_exited

#func _process(_delta):
#	print_orphan_nodes()

func initializePlayerParty():
	if getCombatantSquad('Player').is_empty():
		return
	
	for member in getCombatantSquad('Player'):
		if !member.initialized:
			member.initializeCombatant()
			member.SCENE.free()
	
	loadFollowers()

func setPlayerInput(enabled:bool, disable_collision=false, hide_player=false):
	getPlayer().can_move = enabled
	getPlayer().set_process_input(enabled)
	
	if enabled:
		getPlayer().set_collision_layer_value(5, true)
		getPlayer().set_collision_mask_value(5, true)
		getPlayer().set_collision_layer_value(1, true)
		getPlayer().set_collision_mask_value(1, true)
		getPlayer().show()
	else:
		getPlayer().sprinting = false
	
	if disable_collision:
		getPlayer().set_collision_layer_value(5, false)
		getPlayer().set_collision_mask_value(5, false)
		getPlayer().set_collision_layer_value(1, false)
		getPlayer().set_collision_mask_value(1, false)
	if hide_player:
		getPlayer().hide()

func inDialogue() -> bool:
	return getCurrentMap().has_node('Balloon')

#********************************************************************************
# SIGNALS
#********************************************************************************
func moveEntity(entity_body_name: String, move_to, offset=Vector2(0,0), speed=100.0, animate_direction=true, wait=true):
	if getEntity(entity_body_name).has_node('ScriptedMovementComponent'):
		await getEntity(entity_body_name).get_node('ScriptedMovementComponent').tree_exited
	
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
		print('Invalid move_to parameter "', move_to, '"')
	
	if wait:
		await getEntity(entity_body_name).get_node('ScriptedMovementComponent').movement_finished

#********************************************************************************
# GENERAL UTILITY
#********************************************************************************
func getPlayer()-> PlayerScene:
	if !get_tree().current_scene.has_node('Player'):
		return null
	
	return get_tree().current_scene.get_node('Player')

func flattenY(vector)-> Vector2:
	return Vector2(vector.x,0)

func distanceX(position_a, position_b):
	return flattenY(position_a).distance_to(flattenY(position_b))

func getEntity(entity_name: String):
	return get_tree().current_scene.get_node(entity_name)

func hasEntity(entity_name: String):
	return get_tree().current_scene.has_node(entity_name)

func playEntityAnimation(entity_name: String, animation_name: String, reset:bool=false,wait=true):
	getEntityAnimator(entity_name).play(animation_name)
	if reset:
		await getEntityAnimator(entity_name).animation_finished
		getEntityAnimator(entity_name).play('RESET')
	if wait:
		await getEntityAnimator(entity_name).animation_finished

func getEntityAnimator(entity_name: String)-> AnimationPlayer:
	for child in getEntity(entity_name).get_children():
		if child is AnimationPlayer: return child
	
	return null

func changeEntityVisibility(entity_name: String, visibility:bool):
	if get_tree().current_scene.get_node(entity_name) is PlayerScene:
		getPlayer().sprite.visible = visibility
	else:
		get_tree().current_scene.get_node(entity_name).visible = visibility

func shakeSprite(entity: Node2D, strength:float=15.0, speed:float=50.0, sprite_name:String='Sprite2D'):
	if !entity.has_node(sprite_name):
		return
	
	var sprite = entity.get_node(sprite_name)
	var sprite_shaker: SpriteShaker = load("res://scenes/components/SpriteShaker.tscn").instantiate()
	sprite_shaker.shake_speed = speed
	sprite_shaker.shake_strength = strength
	sprite.add_child(sprite_shaker)

func teleportEntity(entity_name, teleport_to, offset=Vector2(0, 0)):
	if teleport_to is Vector2:
		getEntity(entity_name).global_position = teleport_to + offset
	elif teleport_to is String:
		getEntity(entity_name).global_position = getEntity(teleport_to).global_position + offset

func showMenu(path: String):
	var main_menu: Control = load(path).instantiate()
	main_menu.scale = Vector2.ZERO
	main_menu.name = 'uiMenu'
	getPlayer().resetStates()
	getPlayer().sprinting = false
	getPlayer().velocity = Vector2.ZERO
	setPlayerInput(false)
	if !inMenu():
		getPlayer().showOverlay(Color.BLACK, 0.5)
		if isPlayerCheating(): getPlayer().get_node('DebugComponent').hide()
		setMouseController(true)
		getPlayer().player_camera.add_child(main_menu)
		create_tween().tween_property(main_menu,'scale',Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_CUBIC)
		setPlayerInput(false)
	else:
		if isPlayerCheating(): getPlayer().get_node('DebugComponent').show()
		closeMenu(main_menu)


func setMouseController(set_to:bool):
	if has_node('MouseController') and set_to:
		return
	
	if set_to:
		var mouse_controller = load("res://scenes/user_interface/MouseController.tscn").instantiate()
		add_child(mouse_controller)
		Input.warp_mouse(Vector2(DisplayServer.screen_get_size()/2))
	else:
		if has_node('MouseController'): get_node('MouseController').queue_free()

func closeMenu(menu: Control):
	getPlayer().hideOverlay()
	setMouseController(false)
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
	main_menu.scale = Vector2.ZERO
	main_menu.wares_array = getComponent(shopkeeper_name, 'ShopWares').SHOP_WARES
	main_menu.buy_modifier = buy_mult
	main_menu.sell_modifier = sell_mult
	main_menu.open_description = entry_description
	main_menu.name = 'uiMenu'
	
	if !inMenu():
		setMouseController(true)
		getPlayer().player_camera.add_child(main_menu)
		create_tween().tween_property(main_menu,'scale',Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_CUBIC)
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
	button.custom_minimum_size.x = 32
	button.custom_minimum_size.y = 32
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#button.expand_icon = true
	button.icon = item.ICON
	button.tooltip_text = item.NAME
	button.description_text = item.getInformation()
	button.description_offset = Vector2(0, -28)
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
	
	if item is ResStackItem and item.BARTER_ITEM: # item.MANDATORY
		button.theme = preload("res://design/ItemButtonsMandatory.tres")
	else:
		button.theme = preload("res://design/ItemButtons.tres")
	#TEMP
	
	
	return button

func createAbilityButton(ability: ResAbility, large_icon:bool=false)-> CustomAbilityButton:
	var button: CustomAbilityButton = preload("res://scenes/user_interface/AbilityButton.tscn").instantiate()
	button.ability = ability
	button.outside_combat = large_icon
	#button.custom_minimum_size.x = 32
	#button.custom_minimum_size.y = 32
	#button.expand_icon = true
	#button.icon = ability.ICON
	#button.tooltip_text = ability.NAME
	#button.initialize()
	return button

func showPlayerPrompt(message: String, time=5.0, audio_file = ''):
	OverworldGlobals.getPlayer().prompt.showPrompt(message, time, audio_file)

func changeMap(map_name_path: String, coordinates: String='0,0,0',to_entity: String='',show_transition:bool=true,save:bool=false):
	if getCurrentMap().has_node('Player') and getCurrentMap().give_on_exit and !getCurrentMap().REWARD_BANK.is_empty():
		delayed_rewards = getCurrentMap().REWARD_BANK
	
	if show_transition:
		getPlayer().velocity = Vector2.ZERO
		setPlayerInput(false, true)
		await showTransition('FadeIn', getPlayer())
	get_tree().change_scene_to_file(map_name_path)
	await get_tree().process_frame
	
	if getCurrentMap().has_node('Player'): 
		getCurrentMap().hide()
		getPlayer().loadData()
	var player
	match player_type:
		PlayerType.WILLIS: player = load("res://scenes/entities/Player.tscn").instantiate()
		PlayerType.ARCHIE: player = load("res://scenes/entities/PlayerAlternate.tscn").instantiate()
	var coords = coordinates.split(',')
	getCurrentMap().add_child(player) 
	if to_entity != '':
		player.global_position = getEntity(to_entity).global_position + Vector2(0, 20)
	else:
		player.global_position = Vector2(float(coords[0]),float(coords[1]))
	match int(coords[2]):
		0: player.direction = Vector2(0,1) # Down
		179: player.direction = Vector2(0,-1) # Up
		-90: player.direction = Vector2(1, 0) # Right
		90: player.direction = Vector2(-1,0) # Left
	if OverworldGlobals.getCurrentMap().SAFE:
		OverworldGlobals.loadFollowers()
	if save:
		SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME)
	getCurrentMap().show()
	if show_transition:
		showTransition('FadeOut', player)
	if !delayed_rewards.is_empty():
		getCurrentMap().REWARD_BANK = delayed_rewards
		#await getCurrentMap().ready
		getCurrentMap().giveRewards()
		await SaveLoadGlobals.done_saving
		delayed_rewards.clear()
	
	#print(getCurrentMap().NAME, ' <=========================================')

func forceGiveRewards():
	getCurrentMap().giveRewards(true)

func showTransition(animation: String, player_scene:PlayerScene=null):
	var transition = preload("res://scenes/miscellaneous/BattleTransition.tscn").instantiate()
	if player_scene == null:
		getPlayer().player_camera.add_child(transition)
	else:
		player_scene.player_camera.add_child(transition)
	transition.get_node('AnimationPlayer').play(animation)
	await transition.get_node('AnimationPlayer').animation_finished

func getCurrentMap()-> MapData:
	return get_tree().current_scene

func getMapRewardBank(key: String):
	return get_tree().current_scene.REWARD_BANK[key]

func setMapRewardBank(key: String, value):
	get_tree().current_scene.REWARD_BANK[key] = value

func getTamedNames():
	var out = []
	for combatant in get_tree().current_scene.REWARD_BANK['tamed']:
		out.append(combatant.NAME)
	return out

func isPlayerCheating()-> bool:
	return getCurrentMap().has_node('Player') and getPlayer().has_node('DebugComponent')

func showGameOver(end_sentence: String=''):
	#await get_tree().process_frame
	if OverworldGlobals.inMenu(): OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	getPlayer().setUIVisibility(false)
	getPlayer().resetStates()
	setPlayerInput(false, true)
	getPlayer().set_process_unhandled_input(false)
	getPlayer().z_index = 20
	#playEntityAnimation('Player', animation)
	var menu: Control = load("res://scenes/user_interface/GameOver.tscn").instantiate()
	menu.z_index = 20
	getPlayer().resetStates()
	setMouseController(true)
	getPlayer().player_camera.add_child(menu)
	if end_sentence == '': 
		end_sentence = [
			"You perished.", 
			"Well that's unfortunate.",
			"Sorry!",
			"There is nobility in the attempt.",
			"Don't give up!",
			"Try again.",
			"Let's hope the penalty isn't too high."
		].pick_random()
	menu.end_sentence.text = end_sentence

func moveCamera(to, duration:float=0.25, offset:Vector2=Vector2.ZERO, wait:bool=false):
	var tween = create_tween()
	if to is String and to.to_upper() == 'RESET':
		tween.tween_property(getPlayer().player_camera, 'position', getPlayer().default_camera_pos, duration)
	elif to is String:
		tween.tween_property(getPlayer().player_camera, 'global_position', getEntity(to).global_position+offset, duration)
	elif to is Vector2:
		tween.tween_property(getPlayer().player_camera, 'global_position', to+offset, duration)
	elif to is Node2D:
		tween.tween_property(getPlayer().player_camera, 'global_position', to.global_position+offset, duration)
	if wait:
		await tween.finished

func zoomCamera(zoom: Vector2, duration:float=0.25, wait:bool=false):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(getPlayer().player_camera, 'zoom', zoom, duration)
	if wait:
		await tween.finished

func shakeCamera(strength=30.0, speed=20.0):
	getPlayer().player_camera.shake(strength,speed)


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

func loadFollowers():
	for follower in OverworldGlobals.getCurrentMap().get_children().filter(func(child): return child is NPCFollower):
		follower.queue_free()
	player_follower_count = 0
	
	for combatant in PlayerGlobals.TEAM:
		if getCombatantSquad('Player').has(combatant) and combatant.FOLLOWER_TEXTURE != null:
			player_follower_count += 1
			var follower_scene = load("res://scenes/entities/mobs/Follower.tscn").instantiate()
			follower_scene.texture = combatant.FOLLOWER_TEXTURE
			follower_scene.host_combatant = combatant
			follower_scene.follow_index = player_follower_count
			follower_scene.global_position = getPlayer().global_position+Vector2(0, -32)
			getCurrentMap().add_child.call_deferred(follower_scene)

func playSound(filename: String, db=0.0, pitch = 1, random_pitch=true):
	var player = AudioStreamPlayer.new()
	player.bus = "Sounds"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
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
	player.name = filename
	if inCombat():
		CombatGlobals.getCombatScene().add_child(player)
	else:
		add_child(player)
	player.play()

func playSound2D(position: Vector2, filename: String, db=0.0, pitch = 1, random_pitch=true):
	var player = AudioStreamPlayer2D.new()
	player.bus = "Sounds"
	player.connect("finished", player.queue_free)
	player.pitch_scale = pitch
	player.global_position = position
	if filename.begins_with('res://'):
		player.stream = load(filename)
	else:
		player.stream = load("res://audio/sounds/%s" % filename)
	player.volume_db = db
	if random_pitch:
		randomize()
		player.pitch_scale += randf_range(0.0, 0.25)
	call_deferred('add_child', player)
	await player.ready
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

func addEffectPulse(location, radius:float, script:GDScript):
	var pulse: EffectPulse = preload("res://scenes/entities_disposable/EffectPulse.tscn").instantiate()
	pulse.radius = radius
	pulse.hit_script = script
	if location is Node2D:
		location.call_deferred('add_child', pulse)
	elif location is Vector2:
		pulse.global_position = location
		getCurrentMap().call_deferred('add_child', pulse)
	#showQuickAnimation('res://scenes/animations/Reinforcements.tscn', 'Player')
	#showAbilityAnimation('res://scenes/animations/Reinforcements.tscn', OverworldGlobals.getPlayer().global_position)

func showQuickAnimation(animation_id, location, animation_name:String='Show', wait:bool=true):
	var animation: QuickAnimation
	if animation_id is String:
		animation = load(animation_id).instantiate()
	elif animation_id is QuickAnimation:
		animation = animation_id
	elif animation_id is PackedScene:
		animation = animation_id.instantiate()
	animation.animation_name = animation_name
	#animation.process_mode = Node.PROCESS_MODE_ALWAYS
	#animation.z_index = 999
	if !inCombat():
		if location is Node2D:
			location.call_deferred('add_child',animation)
		elif location is String:
			animation.global_position = getEntity(location).global_position
			getCurrentMap().call_deferred('add_child',animation)
		elif location is Vector2:
			animation.global_position = location
			getCurrentMap().call_deferred('add_child',animation)
	else:
		animation.global_position = location
		CombatGlobals.getCombatScene().add_child(animation)
	await animation.ready
	if wait:
		await animation.animation_player.animation_finished

func showAbilityAnimation(animation_path, location, properties:Dictionary={}):
	var animation: AbilityAnimation = load(animation_path).instantiate()
	for property in properties.keys():
		animation.set(property, properties[property])
	if location is Node2D:
		location.call_deferred('add_child', animation)
	else:
		getCurrentMap().call_deferred('add_child', animation)
	await animation.ready
	if location is Vector2:
		animation.playAnimation(location)
	elif location is Node2D:
		animation.playNow()

func shootProjectile(projectile: Projectile, origin, direction: float):
	if origin is Vector2:
		projectile.global_position = origin
	elif origin is Node2D:
		projectile.SHOOTER = origin
	
	add_child(projectile)
	projectile.rotation_degrees = direction

#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
func changeToCombat(entity_name: String, data: Dictionary={}):
	# Check validity
	if get_parent().has_node('CombatScene'):
		await getCurrentMap().get_node('CombatScene').tree_exited
	if getCurrentMap().has_node('Balloon'):
		getCurrentMap().get_node('Balloon').queue_free()
		await getCurrentMap().get_node('Balloon').tree_exited
	if getCombatantSquad('Player').is_empty() or getCombatantSquadComponent('Player').isTeamDead():
		showGameOver('You could not defend yourself!')
		return
	if inMenu():
		showMenu("res://scenes/user_interface/PauseMenu.tscn")
	entering_combat=true
	# Enter combat
	getPlayer().resetStates()
	OverworldGlobals.getPlayer().setUIVisibility(false)
	moveCamera(getEntity(entity_name).get_node('Sprite2D'), 0.05, Vector2.ZERO, true)
	await zoomCamera(Vector2(2,2), 0.1, true)
	setPlayerInput(false)
	var combat_bubble = preload("res://scenes/components/CombatStartedBubble.tscn").instantiate()
	combat_bubble.hide()
	showCombatStartBars()
	#print(getComponent(entity_name, 'NPCPatrolComponent').STATE)
	if getEntity(entity_name).has_node('NPCPatrolComponent') and getComponent(entity_name, 'NPCPatrolComponent').STATE != 2:
		for member in getCombatantSquad('Player'): CombatGlobals.addStatusEffect(member, 'CriticalEye')
		combat_bubble.animation = 'Show_Surprised'
		playSound("808013__artninja__tmnt_2012_inspired_smokebomb_sounds_05202025_3.ogg")
	elif (getEntity(entity_name).has_node('NPCPatrolComponent') and getComponent(entity_name, 'NPCPatrolComponent').STATE == 2) or !getEntity(entity_name).has_node('NPCPatrolComponent'):
		playSound("808013__artninja__tmnt_2012_inspired_smokebomb_sounds_05202025_1.ogg")
	elif data.keys().has('combat_bubble_anim'):
		combat_bubble.animation = data['combat_bubble_anim']
	getEntity(entity_name).add_child(combat_bubble)
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	var combat_scene: CombatScene = load("res://scenes/gameplay/CombatScene.tscn").instantiate()
	var combat_id = getCombatantSquadComponent(entity_name).UNIQUE_ID
	var enemy_squad = getCombatantSquadComponent(entity_name)
	combat_scene.COMBATANTS.append_array(getCombatantSquad('Player'))
	for combatant in getCombatantSquad('Player'):
		combatant.LINGERING_STATUS_EFFECTS.append_array(getCombatantSquadComponent('Player').afflicted_status_effects)
	for combatant in enemy_squad.COMBATANT_SQUAD:
		if combatant == null: continue
		var duped_combatant = combatant.duplicate()
		for effect in enemy_squad.afflicted_status_effects:
			duped_combatant.LINGERING_STATUS_EFFECTS.append(effect)
		if CombatGlobals.randomRoll(enemy_squad.TAMEABLE_CHANCE):
			randomize()
			duped_combatant.SPAWN_ON_DEATH = getRandomTameable().pick_random().convertToEnemy('Feral')
		combat_scene.COMBATANTS.append(duped_combatant)
	if data.keys().has('combat_event'):
		combat_scene.combat_event = load("res://resources/combat/events/%s.tres" % data['combat_event'])
	elif getCurrentMap().EVENTS['combat_event'] != null:
		combat_scene.combat_event = getCurrentMap().EVENTS['combat_event']
	if data.keys().has('initial_damage'):
		combat_scene.initial_damage = data['initial_damage']
	if combat_id != null:
		combat_scene.unique_id = combat_id
	combat_scene.enemy_reinforcements = getCombatantSquad(entity_name)
	combat_scene.do_reinforcements = getCombatantSquadComponent(entity_name).DO_REINFORCEMENTS
	combat_scene.can_escape = getCombatantSquadComponent(entity_name).CAN_ESCAPE
	combat_scene.turn_time = getCombatantSquadComponent(entity_name).TURN_TIME
	combat_scene.reinforcements_turn = getCombatantSquadComponent(entity_name).REINFORCEMENTS_TURN
	var combat_music = CombatGlobals.FACTION_PATROLLER_PROPERTIES[getCombatantSquadComponent(entity_name).getMajorityFaction()].music
	if !combat_music.is_empty():
		combat_scene.battle_music_path = combat_music.pick_random()
	await combat_bubble.animator.animation_finished
	var battle_transition = preload("res://scenes/miscellaneous/BattleTransition.tscn").instantiate()
	getPlayer().player_camera.add_child(battle_transition)
	battle_transition.get_node('AnimationPlayer').play('In')
	await battle_transition.get_node('AnimationPlayer').animation_finished
	#getPlayer().player_camera.remove_child('BattleStart')
	getPlayer().player_camera.get_node('BattleStart').queue_free()
	combat_bubble.queue_free()
	combat_enetered.emit()
	get_parent().add_child(combat_scene)
	combat_scene.combat_camera.make_current()
	if getEntity(entity_name).has_node('CombatDialogue'):
		combat_scene.combat_dialogue = getComponent(entity_name, 'CombatDialogue')
	getCurrentMap().hide()
	await combat_scene.combat_done
	
	# Exit combat
	moveCamera('Player', 0.0, getPlayer().sprite.offset)
	zoomCamera(Vector2(1.0,1.0), 0.0)
	var combat_results = combat_scene.combat_result
	var tamed = combat_scene.tamed_combatants
	getPlayer().player_camera.make_current()
	get_tree().paused = false
	getCurrentMap().show()
	getPlayer().resetStates()
	if combat_results == 1:
		for combatant in tamed: getMapRewardBank('tamed').append(combatant)
	for combatant in getCombatantSquad('Player'):
		for effect in getCombatantSquadComponent('Player').afflicted_status_effects:
			combatant.LINGERING_STATUS_EFFECTS.erase(effect)
	getCombatantSquadComponent('Player').afflicted_status_effects.clear()
	OverworldGlobals.getPlayer().setUIVisibility(true)
	battle_transition.get_node('AnimationPlayer').play('Out')
	await battle_transition.get_node('AnimationPlayer').animation_finished
	battle_transition.queue_free()
	if hasCombatDialogue(entity_name) and combat_results == 1:
		showDialogueBox(getComponent(entity_name, 'CombatDialogue').dialogue_resource, 'win_aftermath')
		await DialogueManager.dialogue_ended
	if combat_results != 0:
		await get_tree().process_frame
		setPlayerInput(true)
	combat_exited.emit()
	entering_combat=false
	#if !isPlayerAlive(): showGameOver('You succumbed to overtime damage!')

func showCombatStartBars():
	var bars = load("res://scenes/user_interface/BattleStart.tscn").instantiate()
	getPlayer().player_camera.add_child(bars)
	bars.position = Vector2.ZERO
	bars.get_node('AnimationPlayer').play('Show')
	

func getRandomTameable():
	var path = "res://resources/combat/combatants_player/tameable/"
	var dir = DirAccess.open(path)
	var out = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var combatant = load(path+'/'+file_name)
			out.append(combatant)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	
	return out

func inCombat()-> bool:
	return get_parent().has_node('CombatScene')
	
func hasCombatDialogue(entity_name: String)-> bool:
	return hasEntity(entity_name) and getEntity(entity_name).has_node('CombatDialogue') and getComponent(entity_name, 'CombatDialogue').enabled

func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD

func getCombatant(entity_name: String, combatant_name: String)-> ResCombatant:
	for combatant in getCombatantSquad(entity_name):
		print('Comp ', combatant, ' vs ', combatant_name)
		if combatant.NAME == combatant_name:
			print(combatant)
			return combatant
	
	return null

func setCombatantSquad(entity_name: String, combatants: Array[ResCombatant]):
	get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').COMBATANT_SQUAD = combatants

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

func damageParty(damage:int, death_message:Array[String]=[],lethal:bool=true):
	OverworldGlobals.getPlayer().player_camera.shake(15.0,10.0)
	
	for member in getCombatantSquad('Player'):
		if member.isDead(): continue
		member.STAT_VALUES['health'] -= int(CombatGlobals.useDamageFormula(member, damage))
		if !lethal and member.isDead():
			member.STAT_VALUES['health'] = 1
		if member.isDead():
			OverworldGlobals.playSound("res://audio/sounds/542039__rob_marion__gasp_sweep-shot_1.ogg")
	if isPlayerSquadDead() and !death_message.is_empty():
		randomize()
		showGameOver(death_message.pick_random())
	elif isPlayerSquadDead():
		showGameOver('')
	playSound('522091__magnuswaker__pound-of-flesh-%s.ogg' % randi_range(1, 2), -6.0)
	party_damaged.emit()
	var pop_up = load("res://scenes/user_interface/HealthPopUp.tscn").instantiate()
	OverworldGlobals.getPlayer().player_camera.get_node('Marker2D').add_child(pop_up)

func isPlayerAlive()-> bool:
	for combatant in getCombatantSquad('Player'):
		if !combatant.isDead(): return true
	
	return false

func restorePlayerView():
	getPlayer().player_camera.make_current()
	get_tree().paused = false

func loadFromPath(path:String, key:String, exstension:String='.tres'):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == key+exstension:
				return load(path+'/'+file_name)
	else:
		print("An error occurred when trying to access the path.")
		print(path)

func loadArrayFromPath(path:String, filter=null)-> Array:
	var out = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			out.append(load(path+'/'+file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	if filter != null:
		out = out.filter(filter)
	
	#print('Returning: ', out)
	return out

func freezeFrame(time_scale: float=0.3, duration: float=1.5):
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0

func resetVariables():
	pass
