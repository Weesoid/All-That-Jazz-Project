extends Node

func showPrompt(message: String, time=5.0, audio_file = ''):
	OverworldGlobals.player.player_camera.player_ui.player_prompt.showPrompt(message, time, audio_file)

func addTooltip(control:Control, text:String, tooltip_position:CustomTooltip.AnchorPreset,show_delay:float=0.5, shrink:bool=false, alignment:CustomTooltip.TextAlignment=CustomTooltip.TextAlignment.LEFT, show_on_hover:bool=true):
	if !is_instance_valid(control): return
	
	var tooltip:CustomTooltip = load("res://scenes/user_interface/CustomTooltip.tscn").instantiate()
	tooltip.name = 'CustomTooltip'
	tooltip.tooltip_position = tooltip_position
	tooltip.show_on_hover = show_on_hover
	tooltip.show_delay = show_delay
	tooltip.shrink = shrink
	tooltip.text_alignment = alignment
	control.add_child(tooltip)
	await get_tree().process_frame
	if !is_instance_valid(tooltip): return
	tooltip.setText(text)
	if !control is Button:
		addFocusMode(control)

func setVerticalNeighbors(container:VBoxContainer):
	var nodes = container.get_children()
	for i in range(nodes.size()):
		var stat_label: Control = nodes[i]
		if stat_label.focus_mode != Control.FOCUS_ALL: continue
		if i-1 >= 0 and nodes[i-1] != null:
			stat_label.focus_neighbor_top =  nodes[i-1].get_path()
		if i+1 <= nodes.size()-1 and nodes[i+1] != null:
			stat_label.focus_neighbor_bottom =  nodes[i+1].get_path()

func addFocusMode(control:Control):
	control.focus_mode = Control.FOCUS_ALL
	control.focus_entered.connect(func():control.modulate=Color.YELLOW)
	control.mouse_entered.connect(func():control.grab_focus())
	control.focus_exited.connect(func():control.modulate=Color.WHITE)

func createCustomButton(theme: Theme = load("res://design/DefaultTheme.tres"))-> CustomButton:
	var button = load("res://scenes/user_interface/CustomButton.tscn").instantiate()
	button.theme = theme
	return button

func createItemButton(item: ResItem, value_modifier: float=0.0, show_count: bool=true, white_borders:bool=false)-> ItemButton:
	var button: CustomButton = load("res://scenes/user_interface/CustomItemButton.tscn").instantiate()
	button.item = item
	button.focused_entered_sound = load("res://audio/sounds/421453__jaszunio15__click_190.ogg")
	button.click_sound = load("res://audio/sounds/421461__jaszunio15__click_46.ogg")
	button.custom_minimum_size.x = 32
	button.custom_minimum_size.y = 32
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon = item.icon
	#button.tooltip_text = item.name
	button.description_text = item.getInformation()
	if item is ResStackItem and show_count:
		var count_label = StackCountLabel.new(item)
		button.add_child(count_label)
	elif item.isRepairable():
		var durability_bar = load("res://scenes/user_interface/DurabilityBar.tscn").instantiate()
		durability_bar.item = item
		InventoryGlobals.item_repaired.connect(durability_bar.update_values.unbind(2))
		button.add_child(durability_bar)
		#durability_bar.setWeapon(item)
	
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
	#addTooltip(button, item.getInformation(), CustomTooltip.AnchorPreset.BOTTOM)
	return button

func createItemIcon(item: ResItem, count:int):
	var icon: TextureRect = TextureRect.new()
	icon.texture = item.icon.duplicate()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.pivot_offset = Vector2(icon.size.x/2,icon.size.y/2)
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.theme = load("res://design/OutlinedLabel.tres")
	count_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	icon.add_child(count_label)
	return icon

func createAbilityButton(ability: ResAbility)-> CustomAbilityButton:
	var button: CustomAbilityButton = load("res://scenes/user_interface/AbilityButton.tscn").instantiate()
	button.ability = ability
	button.outside_combat = !CombatGlobals.inCombat()
	if button.outside_combat:
		button.theme = load("res://design/AbilityButtonsOutCombat.tres")
	return button

func createTalentButton(talent: ResTalent, combatant:ResPlayerCombatant)-> CustomTalentButton:
	var button: CustomTalentButton = load("res://scenes/user_interface/TalentButton.tscn").instantiate()
	button.talent = talent
	button.combatant = combatant
	if button.outside_combat:
		button.theme = load("res://design/AbilityButtonsOutCombat.tres")
	return button

func createCharacterButton(combatant:ResPlayerCombatant)-> CharacterButton:
	var button: CharacterButton = load("res://scenes/user_interface/CharacterButton.tscn").instantiate()
	button.combatant = combatant
	return button

func showShop(shopkeeper_name: String, buy_mult=1.0, sell_mult=0.5, entry_description=''):
	var main_menu: Control = load("res://scenes/user_interface/Shop.tscn").instantiate()
	main_menu.scale = Vector2.ZERO
	main_menu.wares_array = OverworldGlobals.getComponent(shopkeeper_name, 'ShopWares').shop_wares
	main_menu.buy_modifier = buy_mult
	main_menu.sell_modifier = sell_mult
	main_menu.open_description = entry_description
	main_menu.name = 'uiMenu'
	if !inMenu():
		setMouseController(true)
		OverworldGlobals.player.player_camera.get_node('UI').add_child(main_menu)
		create_tween().tween_property(main_menu,'scale',Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_CUBIC)
		OverworldGlobals.setPlayerInput(false)
		#show_player_interaction = false
	else:
		closeMenu(main_menu)

func setMouseController(set_to:bool):
	if has_node('MouseController') and set_to:
		return
	
	if set_to:
		var mouse_controller = load('res://scenes/user_interface/MouseController.tscn').instantiate()
		add_child(mouse_controller)
		Input.warp_mouse(Vector2(DisplayServer.screen_get_size()/2))
	elif has_node('MouseController'): 
		get_node('MouseController').queue_free()

func inMenu():
	return OverworldGlobals.player.player_camera.get_node('UI').has_node('uiMenu')

func getMenu():
	return OverworldGlobals.player.player_camera.get_node('UI').get_node('uiMenu')

func closeMenu(menu: Control=getMenu()):
	OverworldGlobals.player.setUIVisibility(true)
	setMouseController(false)
	menu.queue_free()
	OverworldGlobals.player.player_camera.get_node('UI').get_node('uiMenu').queue_free()
	OverworldGlobals.setPlayerInput(true)

func showMenu(path: String, as_submenu:bool=false):
	if !canShowMenu():
		return
	
	#player.player_camera.player_ui.hide()
	var main_menu: Control = load(path).instantiate()
	if !as_submenu:
		main_menu.name = 'uiMenu'
		OverworldGlobals.player.suddenStop()
		OverworldGlobals.player.resetStates()
		OverworldGlobals.player.setUIVisibility(false)
		OverworldGlobals.setPlayerInput(false)
		if !inMenu():
			if OverworldGlobals.isPlayerCheating(): 
				OverworldGlobals.player.get_node('DebugComponent').hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			setMouseController(true)
			OverworldGlobals.player.player_camera.get_node('UI').add_child(main_menu)
			OverworldGlobals.setPlayerInput(false)
		else:
			if OverworldGlobals.isPlayerCheating(): 
				OverworldGlobals.player.get_node('DebugComponent').show()
			closeMenu(main_menu)
	else:
			closeSubmenu()

func canShowMenu():
	return OverworldGlobals.player.is_on_floor()

func closeSubmenu():
	#player.player_camera.player_ui.show()
	if !OverworldGlobals.player.player_camera.get_node('UI').get_node('uiMenu').has_node('uiSubmenu'):
		return
	OverworldGlobals.player.player_camera.get_node('UI').get_node('uiMenu').get_node('uiSubmenu').queue_free()

func setControlFocus(control):
	for child in control.get_children():
		if child is Button:
			child.grab_focus()
			return
		elif child is Container and containerHasButtons(child):
			getContainerButton(child).grab_focus()
			return

func containerHasButtons(container: Container):
	return container.get_children().filter(func(control): return control is Button).size() > 0

func getContainerButton(container: Container)-> Button:
	for child in container.get_children():
		if child is Button:
			return child
	return null

func insertTextureCode(texture: Texture)-> String:
	return '[img]%s[/img]' % texture.resource_path

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

func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://scenes/user_interface/DialogueBalloon.tscn")
	var balloon: Node = ExampleBalloonScene.instantiate()
	
	if get_parent().has_node('CombatScene'):
		get_parent().get_node('CombatScene').add_child(balloon) # TO-DO TEST THIS
	else:
		get_tree().current_scene.add_child(balloon)
	#balloon.global_position = OverworldGlobals.player.getPosOffset()+Vector2(margin.size.x/2,-80)
	balloon.start(resource, title, extra_game_states)

func hasCombatDialogue(entity_name: String)-> bool:
	return OverworldGlobals.hasEntity(entity_name) and OverworldGlobals.getEntity(entity_name).has_node('CombatDialogue') and OverworldGlobals.getComponent(entity_name, 'CombatDialogue').enabled

func createAbilityLabel(ability, combatant)-> AbilityLabel:
	var ability_label: AbilityLabel = load("res://scenes/user_interface/AbilityLabel.tscn").instantiate()
	ability_label.tree_entered.connect(
		func(): ability_label.setAbility(ability, combatant),
		CONNECT_ONE_SHOT
		)
	return ability_label

func createStatModifierLabel(p_trait, combatant, left_aligned:bool=false)-> StatModifierLabel:
	var modifier_label: StatModifierLabel = load("res://scenes/user_interface/StatModifierLabel.tscn").instantiate()
	modifier_label.tree_entered.connect(
		func(): 
			modifier_label.setModifier(p_trait, combatant, left_aligned),
			CONNECT_ONE_SHOT
		)
	return modifier_label

func createStatusEffectLabel(effect, combatant)-> StatusEffectLabel:
	var status_label: StatusEffectLabel = load("res://scenes/user_interface/StatusLabel.tscn").instantiate()
	status_label.tree_entered.connect(
		func(): status_label.setStatusEffect(effect, combatant),
		CONNECT_ONE_SHOT
		)
	return status_label
