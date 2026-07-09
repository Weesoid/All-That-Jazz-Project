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

func editTooltip(parent:Control, text:String, append:bool):
	var tooltip:CustomTooltip=null
	for child in parent.get_children():
		if child is CustomTooltip: 
			tooltip = child
			break
	#var tooltip: CustomTooltip = parent.find_children('*', 'CustomTooltip')[0]
	if !append:
		tooltip.setText(text)
	else:
		print(tooltip.getText(), ' + ', text)
		tooltip.setText(tooltip.getText()+text)
	

func setVerticalNeighbors(container:VBoxContainer):
	var nodes = container.get_children()
	for i in range(nodes.size()):
		var stat_label: Control = nodes[i]
		if stat_label.focus_mode != Control.FOCUS_ALL: continue
		if i-1 >= 0 and nodes[i-1] != null:
			stat_label.focus_neighbor_top =  nodes[i-1].get_path()
		if i+1 <= nodes.size()-1 and nodes[i+1] != null:
			stat_label.focus_neighbor_bottom =  nodes[i+1].get_path()

func addFocusMode(control:Control, p_modulate_control:Control=null):
	var modulate_control = control if p_modulate_control == null else p_modulate_control
	var default_modulate = modulate_control.modulate
	control.focus_mode = Control.FOCUS_ALL
	control.focus_entered.connect(
		func():
			modulate_control.modulate=Color.YELLOW
			moveCursorToControl(control)
			)
	control.mouse_entered.connect(
		func(): 
			if control.focus_mode != Control.FOCUS_NONE:
				control.grab_focus()
			)
	control.focus_exited.connect(func():modulate_control.modulate=default_modulate)


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
#	if item is ResStackItem and show_count:
#		var count_label = StackCountLabel.new(item)
#		count_label.name = 'Count'
#		button.add_child(count_label)
#	elif item.isRepairable():
#		var durability_bar = load("res://scenes/user_interface/DurabilityBar.tscn").instantiate()
#		durability_bar.item = item
#		InventoryGlobals.item_repaired.connect(durability_bar.update_values.unbind(2))
#		button.add_child(durability_bar)
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
		setControllerAdapter(true)
		OverworldGlobals.player.player_camera.get_node('UI').add_child(main_menu)
		create_tween().tween_property(main_menu,'scale',Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_CUBIC)
		OverworldGlobals.setPlayerInput(false)
		#show_player_interaction = false
	else:
		closeMenu(main_menu)

func setControllerAdapter(set_to:bool, show_cursor:bool=true):
	if has_node('ControllerAdapter') and set_to:
		return
	
	if set_to:
		var mouse_controller:MouseControllerAdapter = load('res://scenes/user_interface/MouseController.tscn').instantiate()
		mouse_controller.show_cursor = show_cursor
		add_child(mouse_controller)
	elif has_node('ControllerAdapter'): 
		get_node('ControllerAdapter').queue_free()

func isUsingController()-> bool:
	return has_node('ControllerAdapter') and get_node('ControllerAdapter').using_controller

func getControllerAdapter()-> MouseControllerAdapter:
	return get_node('ControllerAdapter')

func moveCursorToControl(control:Control):
	await get_tree().process_frame
	if !isUsingController() or !is_instance_valid(control): #or Input.mouse_mode != Input.MOUSE_MODE_CONFINED:
		return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_viewport().warp_mouse(control.global_position+(control.size/2))
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func inMenu():
	return OverworldGlobals.player.player_camera.get_node('UI').has_node('uiMenu')

func getMenu():
	if OverworldGlobals.player == null:
		return null
	if CombatGlobals.inCombat():
		return CombatGlobals.getCombatScene().combat_ui
	else:
		return OverworldGlobals.player.player_camera.get_node('UI').get_node('uiMenu')

func closeMenu(menu: Control=getMenu()):
	setPlayerUIVisiblity(true)
	#OverworldGlobals.player.setUIVisibility(true)
	setControllerAdapter(false)
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
		UIGlobals.setPlayerUIVisiblity(false)
		#OverworldGlobals.player.setUIVisibility(false)
		OverworldGlobals.setPlayerInput(false)
		if !inMenu():
			if OverworldGlobals.isPlayerCheating(): 
				OverworldGlobals.player.get_node('DebugComponent').hide()
			setControllerAdapter(true)
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

func focusFirstControl():
	var visible_buttons = getMenu().find_children("*","Button").filter(func(control): return control.is_visible_in_tree())
	if visible_buttons.size() == 0:
		return
	
	var focus_button = visible_buttons[0]
	focus_button.grab_focus()
	moveCursorToControl(focus_button)

#func focusEmptyEquipSlot(focused_item:ResItem):
#	var slots = getMenu().find_children("*","EquipSlot")
#	var empty_slots = slots.filter(func(button:ItemSlot):return button.item == null and button._can_drop_data(Vector2.ZERO, focused_item) and button.visible)
#	var focused_slot = empty_slots[0] if empty_slots.size() > 0 else slots[0]
#
#	focused_slot.grab_focus()
#	moveCursorToControl(focused_slot)

func isEmptyEquipslot(equip_slot):
	return equip_slot is EquipSlot# and equip_slot.item == null and canFocus(equip_slot) and isUsingController()

func insertTextureCode(texture: Texture)-> String:
	return '[img]%s[/img]' % texture.resource_path

#func setMenuFocus(container: Control):
#	pass
#	if container.get_child_count() > 0:
#		container.get_child(0).grab_focus()

#func setMenuFocusMode(control_item, mode: bool):
#	pass
#	if control_item is Button:
#		if mode:
#			control_item.focus_mode = Control.FOCUS_ALL
#		else:
#			control_item.focus_mode = Control.FOCUS_NONE
#	elif control_item is Container:
#		for child in control_item.get_children():
#			if child is Button:
#				if mode:
#					child.focus_mode = Control.FOCUS_ALL
#				else:
#					child.focus_mode = Control.FOCUS_NONE

func showDialogueBox(resource: DialogueResource, title: String = "0", extra_game_states: Array = []) -> void:
	var ExampleBalloonScene = load("res://scenes/user_interface/DialogueBalloon.tscn")
	var balloon: Node = ExampleBalloonScene.instantiate()
	
	if get_parent().has_node('CombatScene'):
		get_parent().get_node('CombatScene').add_child(balloon)
	else:
		get_tree().current_scene.add_child(balloon)
	#balloon.global_position = OverworldGlobals.player.getPosOffset()+Vector2(margin.size.x/2,-80)
	balloon.start(resource, title, extra_game_states)

func setPlayerUIVisiblity(set_to:bool):
	var color = Color.WHITE if set_to else Color.TRANSPARENT
	var player:PlayerScene = OverworldGlobals.player
	#for element in player.hud: 
	player.melee_bar.visible = set_to#player.melee_bar.canShow() if set_to else false
	player.current_arrow_icon.visible = set_to#player.current_arrow_icon.canShow() if set_to else false
	create_tween().tween_property(OverworldGlobals.player.player_camera.player_ui, 'modulate', color, 0.5)

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

func focusValidDrop():
	if !isUsingController():
		return
	
	print('tung tung')
	for child in getMenu().find_children('*', 'CustomDragDropButton'):
		if child.has_method('_can_drop_data') and child._can_drop_data(Vector2.ZERO, get_viewport().gui_get_drag_data()) and child.is_visible_in_tree():
			child.grab_focus()
			return

#func _notification(what):
#	if what == NOTIFICATION_DRAG_BEGIN and isUsingController():
#		focusValidDrop()
