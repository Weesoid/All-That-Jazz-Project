extends Node

enum PlayerType {
	WILLIS,
	ARCHIE
}

var entering_combat:bool=false
var player_type: PlayerType = PlayerType.WILLIS
var delayed_rewards: Dictionary
var player_follower_count = 0
var player: PlayerScene

signal update_patroller_modes(mode:int)
signal party_damaged
signal combat_enetered
signal combat_exited
signal group_cleared(group:PatrollerGroup)
signal update_inventory

func initializePlayerParty():
	if getCombatantSquad('Player').is_empty():
		return
	
	for member in getCombatantSquad('Player'):
		if !member.initialized:
			member.initializeCombatant()
			member.combatant_scene.free()
	
	#loadFollowers()

func setPlayerInput(enabled:bool, disable_collision=false, hide_player=false):
	player.can_move = enabled
	player.set_process_input(enabled)
	
	if enabled:
		player.set_collision_layer_value(5, true)
		player.set_collision_mask_value(5, true)
		player.set_collision_layer_value(1, true)
		player.set_collision_mask_value(1, true)
		player.show()
	else:
		player.sprinting = false
	
	if disable_collision:
		player.set_collision_layer_value(5, false)
		player.set_collision_mask_value(5, false)
		player.set_collision_layer_value(1, false)
		player.set_collision_mask_value(1, false)
	if hide_player:
		player.hide()

func inDialogue() -> bool:
	return getCurrentMap().has_node('Balloon')

#********************************************************************************
# SIGNALS
#********************************************************************************
func moveEntity(entity_body_name: String, move_to, offset=Vector2(0,0), speed=100.0, animate_direction=true, wait=true):
	if getEntity(entity_body_name).has_node('ScriptedMovementComponent'):
		await getEntity(entity_body_name).get_node('ScriptedMovementComponent').tree_exited
	
	getEntity(entity_body_name).add_child(load("res://scenes/components/ScriptedMovement.tscn").instantiate())
	getEntity(entity_body_name).get_node('ScriptedMovementComponent').animate_direction = animate_direction
	getEntity(entity_body_name).get_node('ScriptedMovementComponent').move_speed = speed
	if move_to is Vector2:
		getEntity(entity_body_name).get_node('ScriptedMovementComponent').target_positions.append(move_to + offset)
	elif move_to is String and move_to.contains('>'):
		getEntity(entity_body_name).get_node('ScriptedMovementComponent').moveBody(move_to)
	elif move_to is String:
		getEntity(entity_body_name).get_node('ScriptedMovementComponent').target_positions.append(getEntity(move_to).global_position + offset)
	else:
		print('Invalid move_to parameter "', move_to, '"')
	
	if wait:
		await getEntity(entity_body_name).get_node('ScriptedMovementComponent').movement_finished

#********************************************************************************
# GENERAL UTILITY
#********************************************************************************
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
		player.sprite.visible = visibility
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

func showMenu(path: String, as_submenu:bool=false):
	if !canShowMenu():
		return
	
	var main_menu: Control = load(path).instantiate()
	if !as_submenu:
		main_menu.name = 'uiMenu'
		player.suddenStop()
		player.resetStates()
		player.setUIVisibility(false)
		setPlayerInput(false)
		if !inMenu():
			if isPlayerCheating(): player.get_node('DebugComponent').hide()
			setMouseController(true)
			player.player_camera.get_node('UI').add_child(main_menu)
			setPlayerInput(false)
		else:
			if isPlayerCheating(): player.get_node('DebugComponent').show()
			closeMenu(main_menu)
	else:
		if !inSubmenu():
			main_menu.name = 'uiSubmenu'
			main_menu.z_index = 99
			player.player_camera.get_node('UI').get_node('uiMenu').add_child(main_menu)
		else:
			closeSubmenu()

func closeSubmenu():
	if !player.player_camera.get_node('UI').get_node('uiMenu').has_node('uiSubmenu'):
		return
	
	player.player_camera.get_node('UI').get_node('uiMenu').get_node('uiSubmenu').queue_free()

## press_type: 0: Press, 1: Held press
func showMiniMenu(menu, action_button:Button, press_type:int, button_function:Callable, item_filter:Callable=func(_item):pass, secondary_button_function=null):
	var mini_menu = menu.instantiate()
	action_button.add_child(mini_menu)
	mini_menu.z_index = 10
	mini_menu.showItems(item_filter)
	for item in mini_menu.item_button_map.keys():
		var button = mini_menu.item_button_map[item]
		
		if press_type == 0:
			button.pressed.connect(button_function.bind(item))
			if secondary_button_function != null: button.held_press.connect(secondary_button_function.bind(item))
		elif press_type == 1:
			button.held_press.connect(button_function.bind(item))
			if secondary_button_function != null: button.pressed.connect(secondary_button_function.bind(item))
		if button.has_method('updateInformation'):
			update_inventory.connect(button.updateInformation)
#			if press_type == 0:
#				button.pressed.connect(func(): update_inventory.emit())
#			elif press_type == 1:
#				button.held_press.connect(func(): update_inventory.emit())

func canShowMenu():
	return player.is_on_floor()

func setMouseController(set_to:bool):
	if has_node('MouseController') and set_to:
		return
	
	if set_to:
		var mouse_controller = load('res://scenes/user_interface/MouseController.tscn').instantiate()
		add_child(mouse_controller)
		Input.warp_mouse(Vector2(DisplayServer.screen_get_size()/2))
	elif has_node('MouseController'): 
		get_node('MouseController').queue_free()

func closeMenu(menu: Control):
	player.setUIVisibility(true)
	setMouseController(false)
	menu.queue_free()
	player.player_camera.get_node('UI').get_node('uiMenu').queue_free()
	setPlayerInput(true)

func inMenu():
	return player.player_camera.get_node('UI').has_node('uiMenu')

func inSubmenu():
	return player.player_camera.get_node('UI').get_node('uiMenu').has_node('uiSubmenu')

func setControlFocus(control):
	for child in control.get_children():
		if child is Button:
			child.grab_focus()
			return
		elif child is Container and containerHasButtons(child):
			getContainerButton(child).grab_focus()
			return

func setMenuFocus(container: Control):
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

func getContainerButton(container: Container)-> Button:
	for child in container.get_children():
		if child is Button:
			return child
	return null

func containerHasButtons(container: Container):
	return container.get_children().filter(func(control): return control is Button).size() > 0

func insertTextureCode(texture: Texture)-> String:
	return '[img]%s[/img]' % texture.resource_path

func showShop(shopkeeper_name: String, buy_mult=1.0, sell_mult=0.5, entry_description=''):
	var main_menu: Control = load("res://scenes/user_interface/Shop.tscn").instantiate()
	main_menu.scale = Vector2.ZERO
	main_menu.wares_array = getComponent(shopkeeper_name, 'ShopWares').shop_wares
	main_menu.buy_modifier = buy_mult
	main_menu.sell_modifier = sell_mult
	main_menu.open_description = entry_description
	main_menu.name = 'uiMenu'
	
	if !inMenu():
		setMouseController(true)
		player.player_camera.get_node('UI').add_child(main_menu)
		create_tween().tween_property(main_menu,'scale',Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_CUBIC)
		setPlayerInput(false)
		#show_player_interaction = false
	else:
		closeMenu(main_menu)

func createCustomButton(theme: Theme = load("res://design/DefaultTheme.tres"))-> CustomButton:
	var button = load("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.theme = theme
	return button

func createItemButton(item: ResItem, value_modifier: float=0.0, show_count: bool=true, white_borders:bool=false)-> CustomButton:
	var button: CustomButton = load("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.focused_entered_sound = load("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	button.click_sound = load("res://audio/sounds/421461__jaszunio15__click_46.ogg")
	button.custom_minimum_size.x = 32
	button.custom_minimum_size.y = 32
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon = item.icon
	button.tooltip_text = item.name
	button.description_text = item.getInformation()
	button.description_offset = Vector2(0, -28)
	if item is ResStackItem and show_count:
		var count_label = StackCountLabel.new(item)
		button.add_child(count_label)
	
	if value_modifier != 0.0:
		var label = Label.new()
		if item.value * value_modifier <= 0:
			label.text = 'Free'
			label.add_theme_font_size_override('font_size', 6)
		else:
			label.text = str(int(item.value * value_modifier))
		label.theme = load("res://design/OutlinedLabel.tres")
		label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		label.set_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		button.add_child(label)
	
	if item is ResStackItem and item.barter_item: # item.mandatory
		button.theme = load("res://design/ItemButtonsMandatory.tres")
	else:
		button.theme = load("res://design/ItemButtons.tres")
	#TEMP
	
	return button

func createItemIcon(item: ResItem, count:int):
	var icon: TextureRect = TextureRect.new()
	icon.texture = item.icon.duplicate()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.pivot_offset = Vector2(icon.size.x/2,icon.size.y/2)
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.theme = load("res://design/OutlinedLabelThin.tres")
	count_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	icon.add_child(count_label)
	return icon

func createStatusEffectIcon(effect_id,expand=TextureRect.EXPAND_KEEP_SIZE):
	var effect = CombatGlobals.loadStatusEffect(effect_id)
	var icon = TextureRect.new()
	icon.texture = effect.texture
	icon.self_modulate = effect.getIconColor()
	icon.tooltip_text = effect.name+': '+effect.description
	icon.expand_mode = expand
	#icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	return icon

func createAbilityButton(ability: ResAbility)-> CustomAbilityButton:
	var button: CustomAbilityButton = load("res://scenes/user_interface/AbilityButton.tscn").instantiate()
	button.ability = ability
	button.outside_combat = !CombatGlobals.inCombat()
	if button.outside_combat:
		button.theme = load("res://design/AbilityButtonsOutCombat.tres")
	return button


func showPrompt(message: String, time=5.0, audio_file = ''):
	OverworldGlobals.player.player_camera.prompt.showPrompt(message, time, audio_file)

func changeMap(map_name_path: String, coordinates: String='0,0,0',to_entity: Array[String]=[],show_transition:bool=true,save:bool=false):
#	if getCurrentMap().has_node('Player') and getCurrentMap().give_on_exit and !getCurrentMap().REWARD_BANK.is_empty():
#		delayed_rewards = getCurrentMap().REWARD_BANK
	if show_transition:
		player.do_gravity=false
		player.velocity = Vector2.ZERO
		setPlayerInput(false, true)
		await showTransition('FadeIn', player)
	get_tree().change_scene_to_file(map_name_path)
	await get_tree().process_frame
	
#	if getCurrentMap().has_node('Player'): 
#		getCurrentMap().hide()
#		getCurrentMap().get_node('Player').queue_free()
#		player.loadData()
#	var player
	match player_type:
		PlayerType.WILLIS: player = load("res://scenes/entities/Player.tscn").instantiate()
		PlayerType.ARCHIE: player = load("res://scenes/entities/PlayerAlternate.tscn").instantiate()
	var coords = coordinates.split(',')
	getCurrentMap().add_child(player)
	#await player.tree_entered
	if !to_entity.is_empty():
		for ent in to_entity:
			if getCurrentMap().has_node(ent):
				player.global_position = getEntity(ent).global_position + Vector2(0, 20)
				break
	else:
		player.global_position = Vector2(float(coords[0]),float(coords[1]))
	match int(coords[2]):
		0: player.direction = Vector2(0,1) # Down
		179: player.direction = Vector2(0,-1) # Up
		-90: player.direction = Vector2(1, 0) # Right
		90: player.direction = Vector2(-1,0) # Left
#	if OverworldGlobals.getCurrentMap().SAFE:
	OverworldGlobals.loadFollowers()
	if save:
		SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	getCurrentMap().show()
	if show_transition:
		showTransition('FadeOut', player)
	if !delayed_rewards.is_empty():
		getCurrentMap().REWARD_BANK = delayed_rewards
		getCurrentMap().giveRewards()
		await SaveLoadGlobals.done_saving
		delayed_rewards.clear()
	
	#print(getCurrentMap().name, ' <=========================================')

func forceGiveRewards():
	getCurrentMap().giveRewards(true)

func showTransition(animation: String, player_scene:PlayerScene=null):
	var transition = load("res://scenes/miscellaneous/BattleTransition.tscn").instantiate()
	if player_scene == null:
		player.player_camera.add_child(transition)
	else:
		player_scene.player_camera.add_child(transition)
	transition.get_node('AnimationPlayer').play(animation)
	await transition.get_node('AnimationPlayer').animation_finished
	transition.queue_free()

func getCurrentMap()-> MapData:
	return get_tree().current_scene

func getAllPatrollers():
	var patrol_groups = getCurrentMap().getPatrolGroups()
	var patrollers = getCurrentMap().get_children().filter(func(child): return child is GenericPatroller)
	for group in patrol_groups:
		patrollers.append_array(group.getPatrollers())
	
	return patrollers.filter(func(patroller): return is_instance_valid(patroller))

func destroyAllPatrollers(respawn:bool=false):
	for patroller in getAllPatrollers():
		patroller.destroy(false,false)
	#player.player_camera.clearRewardBanks()
	await get_tree().process_frame
	for group in getCurrentMap().getPatrolGroups():
		group.reward_bank = {'loot':{},'experience':0.0}
		if respawn and !group.isCleared():
			group.spawn()

func getMapRewardBank(key: String):
	return get_tree().current_scene.REWARD_BANK[key]

func setMapRewardBank(key: String, value):
	get_tree().current_scene.REWARD_BANK[key] = value

#func getTamedNames():
#	var out = []
#	for combatant in get_tree().current_scene.REWARD_BANK['tamed']:
#		out.append(combatant.name)
#	return out

func isPlayerCheating()-> bool:
	return getCurrentMap().has_node('Player') and player.has_node('DebugComponent')

func showGameOver(end_sentence: String=''):
	destroyAllPatrollers()
	player.setUIVisibility(false)
	player.resetStates()
	setPlayerInput(false)
	player.set_process_unhandled_input(false)
	player.z_index = 20
	player.resetStates()
	await get_tree().process_frame
	#get_tree().
	getCurrentMap().queue_free()
	get_tree().change_scene_to_file("res://scenes/user_interface/GameOver.tscn")
	#playEntityAnimation('Player', animation)
	#var menu: Control = load().instantiate()
	#setMouseController(true)
#	if end_sentence == '': 
#		end_sentence = [
#			"You perished.", 
#			"Well that's unfortunate.",
#			"Sorry!",
#			"There is nobility in the attempt.",
#			"Don't give up!",
#			"Try again.",
#			"Let's hope the penalty isn't too high."
#		].pick_random()
#	menu.end_sentence.text = end_sentence

func moveCamera(to, duration:float=0.25, offset:Vector2=Vector2.ZERO, wait:bool=false):
	var tween = create_tween()
	tween.finished.connect(tween.kill)
	if to is String and to.to_upper() == 'RESET':
		tween.tween_property(player.player_camera, 'position', player.default_camera_pos, duration)
	elif to is String:
		tween.tween_property(player.player_camera, 'global_position', getEntity(to).global_position+offset, duration)
	elif to is Vector2:
		tween.tween_property(player.player_camera, 'global_position', to+offset, duration)
	elif to is Node2D:
		tween.tween_property(player.player_camera, 'global_position', to.global_position+offset, duration)
	if wait:
		await tween.finished

func zoomCamera(zoom: Vector2, duration:float=0.25, wait:bool=false):
	var tween = create_tween()
	tween.finished.connect(tween.kill)
	if player.player_camera.zoom < zoom:
		tween.set_ease(Tween.EASE_IN)
	else:
		tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player.player_camera, 'zoom', zoom, duration)
	if wait:
		await tween.finished

func shakeCamera(strength=30.0, speed=20.0):
	player.player_camera.shake(strength,speed)


#********************************************************************************
# OVERWORLD FUNCTIONS AND UTILITIES
#********************************************************************************
func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://scenes/user_interface/DialogueBalloon.tscn")
	var balloon: Node = ExampleBalloonScene.instantiate()
	
	if get_parent().has_node('CombatScene'):
		get_parent().get_node('CombatScene').add_child(balloon) # TO-DO TEST THIS
	else:
		get_tree().current_scene.add_child(balloon)
	#balloon.global_position = OverworldGlobals.player.getPosOffset()+Vector2(margin.size.x/2,-80)
	balloon.start(resource, title, extra_game_states)

func loadFollowers():
	for follower in OverworldGlobals.getCurrentMap().get_children().filter(func(child): return child is NPCFollower):
		follower.queue_free()
	player_follower_count = 0
	
	for combatant in PlayerGlobals.team:
		if getCombatantSquad('Player').has(combatant) and combatant.follower_texture != null:
			player_follower_count += 1
			var follower_scene: Node2D = load("res://scenes/entities/mobs/Follower.tscn").instantiate()
			follower_scene.texture = combatant.follower_texture
			follower_scene.host_combatant = combatant
			follower_scene.follow_index = player_follower_count
			follower_scene.global_position = player.global_position+Vector2(0, -32)
			#follower_scene.sprite.offset.y = -24 
			getCurrentMap().add_child.call_deferred(follower_scene)
			#follower_scene.visible = player.visible
			#await follower_scene.tree_entered

func fadeFollowers(color: Color):
	for follower in PlayerGlobals.getActiveFollowers():
		follower.fade(color)

func playSound(filename: String, db=0.0, pitch = 1, random_pitch=true):
	var audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Sounds"
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player.connect("finished", audio_player.queue_free)
	audio_player.pitch_scale = pitch
	if filename.begins_with('res://'):
		audio_player.stream = load(filename)
	else:
		audio_player.stream = load("res://audio/sounds/%s" % filename)
	audio_player.volume_db = db
	if random_pitch:
		randomize()
		audio_player.pitch_scale += randf_range(0.0, 0.25)
	audio_player.name = filename
	if inCombat():
		CombatGlobals.getCombatScene().add_child(audio_player)
	else:
		add_child(audio_player)
	audio_player.play()

func playSound2D(position: Vector2, filename: String, db=0.0, pitch = 1, random_pitch=true, pitch_range=[0,0.25]):
	if !CombatGlobals.inCombat() and player.getPosOffset().distance_to(position) > 300:
		return
	
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.bus = "Sounds"
	audio_player.connect("finished", audio_player.queue_free)
	audio_player.pitch_scale = pitch
	audio_player.global_position = position
	if filename.begins_with('res://'):
		audio_player.stream = load(filename)
	else:
		audio_player.stream = load("res://audio/sounds/%s" % filename)
	audio_player.volume_db = db
	if random_pitch:
		randomize()
		audio_player.pitch_scale += randf_range(pitch_range[0], pitch_range[1])
	call_deferred('add_child', audio_player)
	await audio_player.ready
	audio_player.play()

func addPatrollerPulse(location, radius:float, mode:int, trigger_others:bool=false):
	var pulse = load("res://scenes/entities_disposable/PatrollerPulse.tscn").instantiate()
	pulse.radius = radius
	pulse.mode = mode
	pulse.trigger_others = trigger_others
	if location is Node2D:
		location.call_deferred('add_child', pulse)
	elif location is Vector2:
		pulse.global_position = location
		getCurrentMap().call_deferred('add_child', pulse)

func addEffectPulse(location, radius:float, script:GDScript):
	var pulse: EffectPulse = load("res://scenes/entities_disposable/EffectPulse.tscn").instantiate()
	pulse.radius = radius
	pulse.hit_script = script
	if location is Node2D:
		location.call_deferred('add_child', pulse)
	elif location is Vector2:
		pulse.global_position = location
		getCurrentMap().call_deferred('add_child', pulse)
	#showQuickAnimation('res://scenes/animations/Reinforcements.tscn', 'Player')
	#showAbilityAnimation('res://scenes/animations/Reinforcements.tscn', OverworldGlobals.player.global_position)

func showQuickAnimation(animation_id, location, animation_name:String='Show', hide_scene:bool=false,wait:bool=true):
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
			if hide_scene: location.hide()
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
	if hide_scene and location is Node2D:
		location.show()

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
		projectile.shooter = origin
	
	add_child(projectile)
	projectile.rotation_degrees = direction

#********************************************************************************
# COMBAT RELATED FUNCTIONS AND UTILITIES
#********************************************************************************
## Used to queue combat after dialogue!
func queueCombat(entity_name: String, data: Dictionary={}):
	DialogueManager.dialogue_ended.connect(func(_dialogue): changeToCombat(entity_name,data),CONNECT_ONE_SHOT)

# Disgusting...... absolutely disgusting...............
func changeToCombat(entity_name: String, data: Dictionary={}, patroller:GenericPatroller=null):
	if entering_combat:
		return
	if get_parent().has_node('CombatScene'):
		await getCurrentMap().get_node('CombatScene').tree_exited
#	if getCurrentMap().has_node('Balloon'):
#		getCurrentMap().get_node('Balloon').queue_free()
		await getCurrentMap().get_node('Balloon').tree_exited
	if getCombatantSquad('Player').is_empty() or getCombatantSquadComponent('Player').isTeamDead():
		showGameOver('You could not defend yourself!')
		return
	if patroller != null and !is_instance_valid(patroller):
		return
	if inMenu():
		showMenu("res://scenes/user_interface/PauseMenu.tscn")
	entering_combat=true
	
	# Enter combat
	#await get_tree().create_timer(0.5).timeout
	var combat_entity 
	var give_non_pg_reward:bool=false
	if patroller == null:
		combat_entity = getEntity(entity_name)
		give_non_pg_reward=true
	else:
		combat_entity = patroller
	player.resetStates()
	OverworldGlobals.player.setUIVisibility(false)
	moveCamera(combat_entity.get_node('Sprite2D'), 0.05, Vector2.ZERO, true)
	await zoomCamera(Vector2(2,2), 0.1, true)
	setPlayerInput(false)
#	showCombatStartBars()
	if combat_entity is GenericPatroller and combat_entity.state != 1:
		for member in getCombatantSquad('Player'): CombatGlobals.addStatusEffect(member, 'CriticalEye')
		playSound("808013__artninja__tmnt_2012_inspired_smokebomb_sounds_05202025_3.ogg")
	else:
		playSound("808013__artninja__tmnt_2012_inspired_smokebomb_sounds_05202025_1.ogg")
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	
	var combat_scene: CombatScene = load("res://scenes/gameplay/CombatScene.tscn").instantiate()
	var combat_id = combat_entity.get_node('CombatantSquadComponent').unique_id
	var enemy_squad = combat_entity.get_node('CombatantSquadComponent')
	var map_events = getCurrentMap().events
	if map_events.has('patroller_effect'):
		enemy_squad.addLingeringEffect(map_events['patroller_effect'])
	combat_scene.combatants.append_array(getCombatantSquad('Player'))
	for combatant in getCombatantSquad('Player'):
		combatant.lingering_effects.append_array(getCombatantSquadComponent('Player').afflicted_status_effects)
	for combatant in enemy_squad.combatant_squad:
		if combatant == null: continue
		var duped_combatant = combatant.duplicate()
		for effect in enemy_squad.afflicted_status_effects:
			duped_combatant.lingering_effects.append(effect)
		combat_scene.combatants.append(duped_combatant)
	combat_scene.combat_entity = combat_entity
	if data.keys().has('combat_event'):
		combat_scene.combat_event = load("res://resources/combat/events/%s.tres" % data['combat_event'])
	elif map_events.has('combat_event'):
		combat_scene.combat_event = map_events['combat_event']
	if data.keys().has('initial_damage'):
		combat_scene.initial_damage = data['initial_damage']
	if combat_id != null:
		combat_scene.unique_id = combat_id
	combat_scene.enemy_reinforcements = enemy_squad.combatant_squad
	combat_scene.do_reinforcements = enemy_squad.do_reinforcements
	combat_scene.can_escape = enemy_squad.can_escape
	combat_scene.turn_time = enemy_squad.turn_time
	combat_scene.reinforcements_turn = enemy_squad.reinforcements_turn
	var combat_music = CombatGlobals.FACTION_PATROLLER_PROPERTIES[enemy_squad.getMajorityFaction()].music
	if !combat_music.is_empty():
		combat_scene.battle_music_path = combat_music.pick_random()
		#await combat_bubble.animator.animation_finished
		#await get_tree().create_timer(0.5).timeout
		#var battle_transition = load("res://scenes/miscellaneous/BattleTransition.tscn").instantiate()
		#player.player_camera.add_child(battle_transition)
		#battle_transition.get_node('AnimationPlayer').play('In')
		#await battle_transition.get_node('AnimationPlayer').animation_finished
		#player.player_camera.get_node('BattleStart').queue_free()
		#combat_bubble.queue_free()
	get_parent().add_child(combat_scene)
	#await combat_scene.tree_entered
	combat_enetered.emit()
	combat_scene.combat_camera.make_current()
	if combat_entity.has_node('CombatDialogue'):
		combat_scene.combat_dialogue = getComponent(entity_name, 'CombatDialogue')
	getCurrentMap().hide()
	await combat_scene.combat_done
	
	# Exit combat
	get_tree().paused = false
	moveCamera('Player', 0.0, player.sprite.offset)
	moveCamera('RESET',0.25)
	zoomCamera(Vector2(1,1),0.25)
	var combat_results = combat_scene.combat_result
	player.player_camera.make_current()
	getCurrentMap().show()
	player.resetStates()
	for combatant in getCombatantSquad('Player'):
		for effect in getCombatantSquadComponent('Player').afflicted_status_effects:
			combatant.lingering_effects.erase(effect)
	getCombatantSquadComponent('Player').afflicted_status_effects.clear()
	OverworldGlobals.player.setUIVisibility(true)
#	battle_transition.get_node('AnimationPlayer').play('Out')
	if combat_entity is GenericPatroller and combat_results == 1:
		addPatrollerPulse(player, 180.0, GenericPatroller.State.CHASING)
		combat_entity.destroy()
#	await battle_transition.get_node('AnimationPlayer').animation_finished
#	battle_transition.queue_free()
	if hasCombatDialogue(entity_name) and combat_results == 1:
		showDialogueBox(getComponent(entity_name, 'CombatDialogue').dialogue_resource, 'win_aftermath')
		await DialogueManager.dialogue_ended
	if combat_results != 0:
		addPatrollerPulse(player, 180.0, GenericPatroller.State.STUNNED)
		await get_tree().process_frame
		setPlayerInput(true)
	combat_exited.emit()
	entering_combat=false
	if combat_results == 1 and give_non_pg_reward:
		giveRewardBank(combat_entity.get_node('CombatantSquadComponent').reward_bank, 'ADVERSARY DEFEATED !')
		combat_entity.get_node('CombatantSquadComponent').reward_bank = {'loot':{},'experience':0.0}
	elif combat_results == 0:
		showGameOver('')

func giveRewardBank(reward_bank: Dictionary,message:String=''):
	var map = getCurrentMap()
	# UI Map clear indicator handling
	var map_clear_indicator = load("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
	map_clear_indicator.added_exp = reward_bank['experience']
	OverworldGlobals.player.player_camera.get_node('UI').add_child(map_clear_indicator)
	if message != '':
		map_clear_indicator.message.text = message
	elif map.getClearState() == map.PatrollerClearState.FULL_CLEAR:
		map_clear_indicator.message.text = 'AREA CLEARED !'
	map_clear_indicator.showAnimation(true, reward_bank)
	
	# Actual giving of rewards
	PlayerGlobals.rested = false
	PlayerGlobals.addExperience(reward_bank['experience'])
	InventoryGlobals.giveItemDict(reward_bank['loot'],false)
	
	# Current map handling
	if map.events.has('bonus_loot'): # Add generated multipliers later
		appendBonusLoot(reward_bank['loot'])
	if map.events.has('bonus_experience'):
		map.events['bonus_experience'] += int(reward_bank['experience']*0.25)

func appendBonusLoot(loot_dict: Dictionary, stack_multiplier:float=0.25):
	var map = getCurrentMap()
	
	for item in loot_dict.keys():
		var stack = ceil(loot_dict[item]*stack_multiplier)
		if map.events['bonus_loot'].has(item):
			map.events['bonus_loot'][item] += stack
		else:
			map.events['bonus_loot'][item] = stack

func showCombatStartBars():
	var bars = load("res://scenes/user_interface/BattleStart.tscn").instantiate()
	player.player_camera.add_child(bars)
	bars.position = Vector2.ZERO
	bars.get_node('AnimationPlayer').play('Show')

func inCombat()-> bool:
	return get_parent().has_node('CombatScene')
	
func hasCombatDialogue(entity_name: String)-> bool:
	return hasEntity(entity_name) and getEntity(entity_name).has_node('CombatDialogue') and getComponent(entity_name, 'CombatDialogue').enabled

func getCombatantSquad(entity_name: String)-> Array[ResCombatant]:
	return get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').combatant_squad

func getCombatant(entity_name: String, combatant_name: String)-> ResCombatant:
	for combatant in getCombatantSquad(entity_name):
		if combatant.name == combatant_name:
			return combatant
	
	return null

func setCombatantSquad(entity_name: String, combatants: Array[ResCombatant]):
	get_tree().current_scene.get_node(entity_name).get_node('CombatantSquadComponent').combatant_squad = combatants

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
	for member in getCombatantSquad('Player'):
		if member.isDead(): continue
		member.stat_values['health'] -= int(CombatGlobals.useDamageFormula(member, damage))
		if !lethal and member.isDead():
			member.stat_values['health'] = 1
		if member.isDead():
			OverworldGlobals.playSound("res://audio/sounds/542039__rob_marion__gasp_sweep-shot_1.ogg")
	
	if !isPlayerSquadDead():
		OverworldGlobals.player.player_camera.shake(15.0,10.0)
		playSound('522091__magnuswaker__pound-of-flesh-%s.ogg' % randi_range(1, 2), -6.0)
		party_damaged.emit()
		var pop_up = load("res://scenes/user_interface/HealthPopUp.tscn").instantiate()
		OverworldGlobals.player.player_camera.get_node('Marker2D').add_child(pop_up)
	else:
		player.do_gravity=false
		setPlayerInput(false,true)
		await get_tree().create_timer(0.25).timeout
		showGameOver()

func damageMember(combatant: ResPlayerCombatant, damage:int, use_damage_formula:bool=true,lethal:bool=false):
	if combatant.isDead():
		return
	OverworldGlobals.player.player_camera.shake(15.0,10.0)
	if use_damage_formula:
		damage = int(CombatGlobals.useDamageFormula(combatant, damage))
	
	combatant.stat_values['health'] -= damage
	if !lethal and combatant.isDead():
		combatant.stat_values['health'] = 1
	if combatant.isDead():
		OverworldGlobals.playSound("res://audio/sounds/542039__rob_marion__gasp_sweep-shot_1.ogg")
	CombatGlobals.manual_call_indicator.emit(combatant, '[color=red]'+str(damage), 'Damage')
	playSound('522091__magnuswaker__pound-of-flesh-%s.ogg' % randi_range(1, 2), -6.0)

func addLingerEffect(combatant: ResCombatant, effect):
	if effect is ResStatusEffect:
		effect = effect.resource_path.get_file().replace('.tres','')
	if effect == '':
		return
	
	var status_effect:ResStatusEffect = CombatGlobals.loadStatusEffect(effect)
	if combatant.lingering_effects.has(effect):
		return false
	else:
		if status_effect.getStatusModiferEffect() != null and combatant is ResPlayerCombatant:
			combatant.temperment.append(CombatGlobals.getTempermentModiferID(status_effect, status_effect.getStatusModiferEffect().status_change))
		
		combatant.lingering_effects.append(effect)
		return true
		
		
func isPlayerAlive()-> bool:
	for combatant in getCombatantSquad('Player'):
		if !combatant.isDead(): return true
	
	return false

func freezeFrame(time_scale: float=0.3, duration: float=1.0):
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0

func resetVariables():
	pass
