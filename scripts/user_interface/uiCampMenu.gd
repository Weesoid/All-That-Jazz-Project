extends Control
class_name CampMenu

const INV_ICON = preload("res://images/sprites/sack_inverted.png")
const FAST_TRAVEL_ICON = preload("res://images/sprites/button_pinpoint_normal.png")

@onready var inventory: MiniInventory = $MiniInventory
@onready var crafting: CraftingMenu = $uiCrafting
@onready var fast_travel = $FastTravel
@onready var fast_travel_button = $HBoxContainer/FastTravel
@onready var crafting_button = $MiniInventory/Control/Crafting
@onready var buttons = $HBoxContainer
@onready var gradient = $TextureRect
@onready var guard_label = $Label
@onready var rest_options = $RestOptions
@onready var rest_button = $HBoxContainer/Rest
@onready var outside_buttons = $OutsideButtons
@onready var set_guard_buttons = $SetGuardButtons
@onready var kindle_slot = $OutsideButtons/KindlingSlot
@onready var roster_container = $Roster
@onready var roster_character_button = $Roster/RosterButtonTemplate
@onready var roster_button = $HBoxContainer/Party
@onready var game_menu = $GameMenu
@onready var char_sheet: CharSheet = $Roster/Control/PanelContainer/MarginContainer/CharacterSheet
@onready var char_sheet_panel = $Roster/Control/PanelContainer
@onready var roster_elements = $Roster/Control
@onready var revive_indicator = $Roster/Control/ReviveIndicator
@onready var revive_indicator_button = $Roster/Control/ReviveIndicator/ReviveIndicator
var kindling_item = preload("res://resources/items/Kindling.tres")
var camp_bars
var original_positions: Dictionary
var guard_combatant:ResPlayerCombatant
var rest_mode:bool=false
var done:bool=false
var camp_buttons: Array[CustomCampButton]
#var guard_buttons: Array[CustomButton]
var camp_spot = OverworldGlobals.player.current_camp_spot
var last_selected_camper: CustomCampButton = null
var last_selected_item: ItemButton = null

signal combatant_revived

func _ready():
	modulate=Color.TRANSPARENT
	revive_indicator.modulate = Color.TRANSPARENT
	camp_bars = camp_spot.getCampBars()
		#bar.pressed.connect(func(): setGuard(bar))
		#setCampButtonCombatant(bar.attached_combatant, bar.name.trim_prefix('Sprite2D'))
	loadRoster()
	#if PlayerGlobals.team.size() <= 4:
	#	roster_button.hide()
	inventory.showItems()
	kindle_slot.can_drop_function = noRestedBuff
	original_positions[crafting] = crafting.position
	original_positions[inventory] = inventory.position
	original_positions[fast_travel] = fast_travel.position
	original_positions[buttons] = buttons.position
	original_positions[gradient] = gradient.position
	original_positions[guard_label] = guard_label.position
	original_positions[rest_options] = rest_options.position
	original_positions[roster_container] = roster_container.position
	setMenuVisibility(crafting, false)
	setMenuVisibility(fast_travel, false)
	setMenuVisibility(roster_container,false)
	setMenuVisibility(guard_label,false,true)
	setMenuVisibility(rest_options,false,true,0.5,true)
	rest_button.setDisabled(true)
	setFullMenuVisibility(false)
	camp_buttons.assign(getCharaterCampButtons())
	#guard_buttons.assign(set_guard_buttons.get_children())
	for button in camp_buttons:
		button.focus_entered.connect(
			func():
				if button.combatant == null: return
				camp_spot.getCombatantBar(button.combatant).setFocusGradient(true)
				)
		button.focus_exited.connect(
			func():
				if button.combatant == null: return
				camp_spot.getCombatantBar(button.combatant).setFocusGradient(false)
				)
	for combatant in OverworldGlobals.getCombatantSquad("Player"):
		var pos = camp_spot.getResterPosition(combatant)
		setCampButtonCombatant(combatant, pos)
	for guard_button in set_guard_buttons.get_children():
		guard_button.pressed.connect(
			func():
				setGuard(guard_button.get_meta('combatant'))
				)
		guard_button.focus_entered.connect(
			func():
				if guard_button.get_meta('combatant') == null or camp_spot.getCombatantBar(guard_button.get_meta('combatant')) == null: return
				camp_spot.getCombatantBar(guard_button.get_meta('combatant')).setFocusGradient(true)
				)
		guard_button.focus_exited.connect(
			func():
				if guard_button.get_meta('combatant') == null or camp_spot.getCombatantBar(guard_button.get_meta('combatant')) == null: return
				camp_spot.getCombatantBar(guard_button.get_meta('combatant')).setFocusGradient(false)
				)
	for button in camp_buttons:
		button.party_wide_item_hovered.connect(showPartyItem)
		button.mouse_exited.connect(hideAllItems)
		button.item_received.connect(focusInventory)
		button.item_received.connect(
			func(item):
				last_selected_camper = button
				last_selected_item = inventory.item_button_map[item][0] if inventory.item_button_map.has(item) else null
				)
		button.combatant_changed.connect(
			func(combatant):
				var index = button.name.trim_prefix('CharacterCampButton')
				setCampButtonCombatant(combatant, index)
				camp_spot.addRestSprite(combatant, int(index))
				#setGuardMeta(index)
				)
		button.held_press.connect(
			func():
				var button_combatant = button.combatant
				if button.combatant == null or button_combatant.mandatory: 
					return
				camp_spot.removeRestSprite(button_combatant)
				PlayerGlobals.removeCombatantFromSquad(button_combatant)
				button.combatant = null
				if roster_container.visible: 
					button.show()
					button.updateGradient()
				else:
					button.hide()
		)
	for button in crafting.crafting_slots:
		button.item_received.connect(focusInventory)
		button.item_received.connect(
			func(item):
				last_selected_item = inventory.item_button_map[item][0] if inventory.item_button_map.has(item) else null
				)
	for item in inventory.getButtons():
		item.item_dragging.connect(focusCamper)
	#camp_spot.camp_kindled.connect(func():rest_button.setDisabled(false))
	await get_tree().create_timer(0.25).timeout
	setFullMenuVisibility(true)
	done=true

#func addFocusSnapping(item_button:ItemButton):
#	item_button.item_dragging.connect(focusCamper.unbind(1))

func loadRoster():
	for member in PlayerGlobals.team:
		var duped_button: CharacterButton = roster_character_button.duplicate()
		roster_container.add_child(duped_button)
		duped_button.show()
		duped_button.setCombatant(member)
		#duped_button.hold_time = 0.25
		duped_button.held_press.connect(reviveCombatant.bind(member))
		duped_button.held_press.connect(hideReviveIndicator.bind(duped_button))
		duped_button.focus_entered.connect(moveReviveIndicator.bind(duped_button))
		duped_button.focus_exited.connect(hideReviveIndicator.bind(duped_button))
		duped_button.drag_start.connect(UIGlobals.focusValidDrop)
		#combatant_revived.connect(duped_button.)
		duped_button.gui_input.connect(
			func(input):
				if InputMap.action_has_event("ui_show_info", input) and input.is_pressed():
					showCharacterSheet(duped_button.combatant)
				)

func reviveCombatant(combatant):
	if !InventoryGlobals.hasItem('SmellingSalts'): return
	
	var revive_item: ResCampItem = InventoryGlobals.getItem('Smelling Salts')
	revive_item.apply(combatant)
	revive_item.take(1)
	#hideReviveIndicator()
	#combatant_revived.emit()

func showCharacterSheet(combatant:ResPlayerCombatant):
	char_sheet.setCombatant(combatant)
	char_sheet_panel.show()

func focusCamper(item):
	if !UIGlobals.isUsingController() or !get_viewport().gui_is_dragging():
		return
	
	if crafting.visible and InventoryGlobals.recipes.size() > 0:
		crafting.focusEmptySlot()
		return
	elif item == kindling_item:
		kindle_slot.grab_focus()
		return
	elif last_selected_camper != null:
		last_selected_camper.grab_focus()
		return
	
	for camp_button in camp_buttons:
		if camp_button.combatant != null:
			camp_button.grab_focus()
			return

func moveReviveIndicator(button):
	if !InventoryGlobals.hasItem('SmellingSalts'): return
	
	revive_indicator.modulate = Color.TRANSPARENT
	if !button.combatant.isDead() or !InventoryGlobals.hasItem(revive_indicator_button.item):
		return
	
	revive_indicator.global_position = button.global_position-Vector2(46,-12)
	button.hold_time = 0.25
	create_tween().tween_property(revive_indicator, 'modulate', Color.WHITE, 0.25)

func hideReviveIndicator(button):
	button.hold_time = -1
	create_tween().tween_property(revive_indicator, 'modulate', Color.TRANSPARENT, 0.25)

#func addSmellingSaltsCounter():
#	var item = InventoryGlobals.loadItemResource('SmellingSalts')
#	var arrow_button = UIGlobals.createItemButton(item)
#	#var count_label = getCountLabel(arrow_button)
#	arrow_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
#	arrow_button.focus_mode=Control.FOCUS_NONE
#	arrow_button.flat = true
#	#count_label.position += Vector2(8,2)
#	add_child(arrow_button)

func focusInventory(item):
	if !UIGlobals.isUsingController() or !get_viewport().gui_is_dragging():
		return
	
	await get_tree().process_frame
	if crafting.craft_item != null:
		crafting.result_slot.grab_focus()
		return
	elif last_selected_item != null:
		last_selected_item.grab_focus()
		return
	
	if !inventory.isCategoryEmpty(inventory.getCategory(item)):
		inventory.focusCategory(item)
	else:
		inventory.focusFirstFilled()

func restockItem(item: ResStackItem):
	if item.stack > 0: inventory.addButton(item)

func showPartyItem(item: ResCampItem):
	for camp_button in camp_buttons:
		if camp_button.combatant != null:camp_button.showAction(item)

func hideAllItems():
	for camp_button in camp_buttons:
		if camp_button.combatant != null: camp_button.showAction(null)

# DUCT TAPE
func _process(delta):
	if !done:
		modulate = Color.TRANSPARENT

func clearPartyItem(item: ResCampItem):
	if !item.party_wide:
		return
	hideAllItems()


func updateStrainBars(_item):
	for bar in camp_bars:
		if bar.attached_combatant != null: bar.updateStrainBar()

func setFullMenuVisibility(set_to:bool):
	var tween = create_tween()
	if set_to:
		tween.tween_property(self,'modulate',Color.WHITE,0.5)
	else:
		tween.tween_property(self,'modulate',Color.TRANSPARENT,0.5)

func setMenuVisibility(menu:Control, set_to:bool, offset_to_top:bool=false,duration:float=0.25, invert_direction:bool=false):
	var tween = create_tween().set_parallel()
	var offset = Vector2(128,0) if !offset_to_top else Vector2(0,-128)
	if invert_direction: offset *= -1
	var pos = original_positions[menu]
	var offscreen_pos = pos+offset
	if menu != roster_container and roster_container.visible:
		setMenuVisibility(roster_container, false)
		for button in camp_buttons: 
			if button.combatant == null: button.hide()
	elif menu == roster_container:
		for button in camp_buttons: 
			button.show()
			button.updateGradient()
		if !outside_buttons.visible:
			outside_buttons.show()
	if menu == inventory and crafting.visible:
		setMenuVisibility(crafting, false)
	
	if set_to:
		menu.show()
		tween.tween_property(menu,'modulate',Color.WHITE,duration)
		tween.tween_property(menu,'position',pos,duration)
	else:
		tween.tween_property(menu,'modulate',Color.TRANSPARENT,duration)
		tween.tween_property(menu,'position',offscreen_pos,duration)
		await tween.finished
		menu.hide()

func setBaseMenuVisibility(set_to:bool, entire_menu:bool=true):
	setMenuVisibility(inventory, set_to)
#	setMenuVisibility(crafting, set_to)
	setMenuVisibility(buttons, set_to)
	setMenuVisibility(gradient, set_to)
	if entire_menu:
		setMenuVisibility(fast_travel, set_to)
		setMenuVisibility(crafting, set_to)

func _on_crafting_pressed():
	crafting.resetCrafting()
	await setMenuVisibility(crafting, crafting.position != original_positions[crafting])
	outside_buttons.visible = !crafting.visible

func _on_fast_travel_pressed():
	showSideMenuVisiblity(fast_travel)

func _on_inventory_pressed():
	showSideMenuVisiblity(inventory)

func _on_party_pressed():
	showSideMenuVisiblity(roster_container)
	

func showSideMenuVisiblity(menu):
	if menu.visible: return
	if menu != inventory: setMenuVisibility(inventory, false)
	if menu != crafting: setMenuVisibility(crafting, false)
	if menu != fast_travel: setMenuVisibility(fast_travel, false)
	if menu != roster_container: setMenuVisibility(roster_container, false)
	setMenuVisibility(menu, true)

func setGuard(combatant:ResPlayerCombatant):
	if !rest_mode:
		return
	for other_bar in camp_spot.getCombatBars(true):
		other_bar.setWatchmark(false)
	
	if combatant == null:
		return
	if combatant == guard_combatant:
		guard_combatant = null
		camp_spot.getCombatantBar(combatant).setWatchmark(false)
	else:
		guard_combatant = combatant
		camp_spot.getCombatantBar(combatant).setWatchmark(true)

func _on_rest_held_press():
	camp_spot.setCamToRestPos()
	#for button in set_guard_buttons.get_children():
	#	if button.visible: button.setDisabled(button.get_meta('combatant').isDead())
	set_guard_buttons.show()
	outside_buttons.hide()
	rest_mode=true
	setBaseMenuVisibility(false)
	setMenuVisibility(guard_label,true,true,0.5)
	setMenuVisibility(rest_options,true,true,0.5,true)

func _on_custom_button_held_press():
	#PlayerGlobals.rested = true
	var squad = OverworldGlobals.getCombatantSquad("Player")
	for combatant in squad:
		if combatant == guard_combatant: 
			CombatGlobals.healResolve(combatant,1)
			continue
		restCombatant(combatant)
	await doScreenFade()
	await get_tree().create_timer(1).timeout
	if guard_combatant == null and CombatGlobals.randomRoll(0.75):
		for combatant in squad: combatant.storeStatusEffect(CombatGlobals.loadStatusEffect('Stunned'))
		OverworldGlobals.player.player_camera.playBigLabelAnimation('Show_Ambush')
		camp_spot.fightCombatantSquad()
		await OverworldGlobals.combat_enetered
		OverworldGlobals.player.player_camera.hideOverlay(0.1)
		await OverworldGlobals.combat_exited
	
	doExitTransition(false)

func restCombatant(combatant: ResPlayerCombatant):
	randomize()
	var random_stat_boost= ['speed', 'damage', 'resolve'].pick_random()
	combatant.addTemporaryModifer('Well Rested',3,{'resist':0.1,random_stat_boost:1,'health':5},false,true)
	CombatGlobals.calculateHealing(combatant, ceil(combatant.getMaxHealth()*0.05),false)
	CombatGlobals.healResolve(combatant,3)
	CombatGlobals.removeInjury(combatant,0.1,randi_range(1,2))

func _on_return_pressed():
	outside_buttons.show()
	set_guard_buttons.hide()
	setGuard(null)
	rest_mode=false
	camp_spot.setCamToMenuPos()
	setMenuVisibility(guard_label,false,true,0.5)
	setMenuVisibility(rest_options,false,true,0.5,true)
	setBaseMenuVisibility(true,false)

func _on_embark_held_press():
	doExitTransition()

func doExitTransition(do_screen_fade:bool=true):
	if do_screen_fade: await doScreenFade()
	#await get_tree().process_frame
	setGuard(null)
	camp_spot.done.emit()
	queue_free()

func doScreenFade():
	setBaseMenuVisibility(false)
	await setFullMenuVisibility(false)
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	await get_tree().create_timer(1.0).timeout

func getCharaterCampButtons():
	return outside_buttons.get_children().filter(func(control): return control is CustomCampButton)

func setCampButtonCombatant(combatant:ResPlayerCombatant, slot:String):
	for button in camp_buttons:
		var button_slot = button.name.trim_prefix('CharacterCampButton')
		#button.rest_sprite = camp_spot.getRestSprite(slot)
		if button_slot == slot:
			button.combatant = combatant
			button.show()
			setGuardMeta(slot)
			return

#func setRosterVisibility(set):
#	setMenuVisibility(roster_container, true)

func noRestedBuff():
	for member in OverworldGlobals.getCombatantSquad('Player'):
		if member.hasTemporaryModifier('Well Rested'):
#			if heads_up_cd.is_stopped():
#				UIGlobals.showPrompt("Already rested.")
#				heads_up_cd.start()
			return false
	
	return true

func _on_kindling_slot_item_received(_item):
	InventoryGlobals.removeItemResource(kindling_item)
	kindle_slot.setDisabled(true)
	rest_button.setDisabled(false)
	camp_spot.kindleFire()

func setGuardMeta(index:String):
	var guard_button = set_guard_buttons.get_node('CustomButton'+index)
	var camp_button = outside_buttons.get_node('CharacterCampButton'+index) 
	guard_button.set_meta('combatant', camp_button.combatant)
	guard_button.show()

func toggleGameMenu(set_to:bool):
	#for menu in get_children(): if menu != game_menu: menu.visible = !set_to
	game_menu.visible = set_to
	if game_menu.visible: 
		outside_buttons.hide()
		game_menu.loadParty()
		game_menu.showTween()
	else:
		outside_buttons.show()
	
	setBaseMenuVisibility(!game_menu.visible, false)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_show_menu"):
		toggleGameMenu(!game_menu.visible)
