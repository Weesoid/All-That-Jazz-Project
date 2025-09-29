extends Control

@onready var action_container = $HBoxContainer
@onready var camp_item_container = $HBoxContainer2
@onready var eat_button = $HBoxContainer/Eat
@onready var craft_button = $HBoxContainer/Craft
@onready var travel_button = $HBoxContainer/FastTravel
@onready var back_button = $BackButton
@onready var rest_button = $HBoxContainer/Rest
@onready var no_rest_button = $HBoxContainer/NoRest
@onready var rest_ui = $RestStuff
@onready var confirm_rest = $RestStuff/ConfirmRest
@onready var squad = OverworldGlobals.getCombatantSquad('Player')
@onready var save_point: SavePoint = OverworldGlobals.getCurrentMap().get_node('SavePoint')
@onready var player_ui_path = OverworldGlobals.player.player_camera.get_node('UI')
var camp_item: ResCampItem
var camp_target: ResPlayerCombatant
var select_guard:bool = false
var guard_combatant: ResPlayerCombatant
var wake_events = [
	'fight',
	'steal',
	'damage',
	'status_effect'
	]

signal update_count(count, item)

func _ready():
	rest_button.disabled = PlayerGlobals.rested and save_point.mind_rested
	showContainer(action_container)
	update_count.connect(updateCount)
	for child in save_point.rest_spots.get_children():
		if child.texture == null:
			continue
		var mini_bar: CombatBarsMini = child.get_node('CombatBars')
		var combatant = mini_bar.attached_combatant
		mini_bar.selector.pressed.connect(
			func():
				if select_guard:
					if guard_combatant == combatant:
						save_point.showWatchMark(guard_combatant,true)
						guard_combatant = null
					else:
						guard_combatant = combatant
						save_point.showWatchMark(guard_combatant)
					if guard_combatant != null:
						confirm_rest.text = 'REST'
					else:
						confirm_rest.text = 'SKIP WATCH'
				elif camp_item != null:
					camp_item.applyEffects(combatant)
					camp_item.take(1)
					update_count.emit(camp_item.stack, camp_item)
					updateCombatants()
		)
		mini_bar.selector.focus_entered.connect(
			func(): 
				if camp_item != null and camp_item.party_wide: 
					highlightAll()
				)

func updateCombatants():
	for combatant in squad:
		getRestSprite(combatant).get_node('CombatBars').updateStatusEffects()

func highlightAll():
	for member in getAllRestSprites(): 
		member.get_node('CombatBars').highlightCombatant()

func unhighlightAll():
	for member in getAllRestSprites(): 
		member.get_node('CombatBars').stopHighlight()

func _on_eat_pressed():
	fillCampItemContainer()
	save_point.setBarVisibility(true)
	showContainer(camp_item_container)

func _on_craft_pressed():
	loadUserInterface("res://scenes/user_interface/Crafting.tscn")

func _on_fast_travel_pressed():
	loadUserInterface("res://scenes/user_interface/FastTravel.tscn")

func setButtons(set_to:bool):
	for button in action_container.get_children():
		button.visible = set_to

func loadUserInterface(path):
	var ui = load(path).instantiate()
	ui.name = 'Menu'
	setButtons(false)
	player_ui_path.add_child(ui)
	back_button.show()

func tweenAbilityButtons(buttons: Array):
	for button in buttons:
		button.modulate = Color.TRANSPARENT
	await get_tree().process_frame
	for button in buttons:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, 'scale', Vector2(1.1,1.1), 0.005)
		tween.tween_property(button, 'scale', Vector2(1.0,1.0), 0.05)
		tween.set_parallel(true)
		tween.tween_property(button, 'modulate', Color.WHITE, 0.0025)
		await tween.finished
		OverworldGlobals.playSound('536805__egomassive__gun_2.ogg',-6.0)

func _on_back_button_pressed():
	back_button.hide()
	if player_ui_path.has_node('Menu'):
		player_ui_path.get_node('Menu').queue_free()
	for child in camp_item_container.get_children():
		child.queue_free()
	save_point.setBarVisibility(false)
	unhighlightAll()
	setButtons(true)
	showContainer(action_container)

func showContainer(container):
	for control in get_children().filter(func(control): return control is Container):
		control.hide()
	if container == null:
		return
	if container != action_container:
		back_button.show()
	else:
		back_button.hide()
	container.show()
	OverworldGlobals.setMenuFocus(container)
	await tweenAbilityButtons(container.get_children())

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_show_menu") and (player_ui_path.has_node('Menu') or camp_item_container.visible):
		_on_back_button_pressed()

func _on_rest_pressed():
	showContainer(null)
	setButtons(false)
	save_point.setBarVisibility(true)
	select_guard = true
	rest_ui.show()

func _on_confirm_rest_pressed():
	PlayerGlobals.rested = true
	rest_ui.hide()
	save_point.setBarVisibility(false)
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	for combatant in squad:
		if combatant == guard_combatant: continue
		restCombatant(combatant)
	await get_tree().create_timer(1.5).timeout
	
	if  guard_combatant == null and CombatGlobals.randomRoll(0.75):
		await pickRandomEvent()
	else:
		await get_tree().create_timer(1.5).timeout
	OverworldGlobals.getCurrentMap().get_node('SavePoint').done.emit()
	queue_free()

func pickRandomEvent():
	randomize()
	var event = wake_events.pick_random()
	match event: # TO DO: Event notifs... barks?
		'fight':
			save_point.fightCombatantSquad()
			OverworldGlobals.player.player_camera.hideOverlay(0)
		'damage':
			OverworldGlobals.damageParty(10,[],false)
		'steal':
			var item = InventoryGlobals.getNonMandatoryItems().pick_random()
			var count = 1
			if item is ResStackItem:
				count = ceil(item.stack*randf_range(0.25,0.5))
			InventoryGlobals.removeItemResource(item,count)
		'status_effect':
			var effect = ['Poison', 'Burn'].pick_random()
			for combatant in squad:
				OverworldGlobals.addLingerEffect(combatant, effect)

func restCombatant(combatant: ResPlayerCombatant):
	if CombatGlobals.getFadedLevel(combatant)>0:
		CombatGlobals.removeLingeringEffect(combatant, CombatGlobals.getFadedStatus(combatant))
	
	CombatGlobals.calculateHealing(combatant, combatant.getMaxHealth()*0.05)

func fillCampItemContainer():
	for item in getCampItems():
		var button = OverworldGlobals.createItemButton(item)
		button.pressed.connect(
			func():
				camp_item = item
				piss(Color(Color.DARK_GRAY, 0.5))
				button.modulate = Color.WHITE
				unhighlightAll()
				)
		button.description_offset=Vector2(0,116)
		camp_item_container.add_child(button)

func updateCount(count, item):
	var button = getItemButton(item)
	button.get_node('Count').text = str(count)
	if count <= 0:
		button.queue_free()
		camp_item = null

func getItemButton(item: ResItem):
	for button in camp_item_container.get_children():
		if button.tooltip_text == item.name:
			return button

func piss(scales):
	for button in camp_item_container.get_children():
		button.modulate = scales

func getRestSprite(combatant: ResPlayerCombatant):
	for sprite in save_point.rest_spots.get_children():
		if sprite.texture == null: continue
		
		if sprite.get_node('CombatBars').attached_combatant == combatant:
			return sprite

func getAllRestSprites():
	var out = []
	for sprite in save_point.rest_spots.get_children():
		if sprite.texture == null: continue
		out.append(sprite)
	return out

func getCampItems():
	return InventoryGlobals.inventory.filter(func(item): return item is ResCampItem)

func _on_no_rest_pressed():
	action_container.hide()
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	#await get_tree().create_timer(1.5).timeout
	save_point.done.emit()
	queue_free()

func _on_inventory_pressed():
	loadUserInterface("res://scenes/user_interface/GameMenu.tscn")

