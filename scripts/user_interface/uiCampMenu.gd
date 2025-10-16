extends Control

enum Mode {
	CAMP,
	SELECT_GUARD,
	ROSTER
}

const SWITCH_ROSTER_ICON = preload("res://images/sprites/icon_rotating_arrows.png")
const ADD_ROSTER_ICON = preload("res://images/sprites/plus_icon_big.png")

#@onready var action_container = $HBoxContainer
@onready var action_bar = $OtherActions
@onready var camping = $Submenus/Camp
@onready var camp_item_container = $Submenus/Camp/MainBar/ScrollContainer/CampItems
@onready var craft_button = $OtherActions/Craft
@onready var travel_button = $OtherActions/FastTravel
@onready var rest_button = $Submenus/Camp/RestOptions/Rest
@onready var no_rest_button = $Submenus/Camp/RestOptions/NoRest
@onready var rest_ui = $RestStuff
@onready var confirm_rest = $RestStuff/HBoxContainer/ConfirmRest
@onready var squad = OverworldGlobals.getCombatantSquad('Player')
@onready var save_point: SavePoint = OverworldGlobals.getCurrentMap().get_node('SavePoint')
@onready var player_ui_path = OverworldGlobals.player.player_camera.get_node('UI')
@onready var sub_menus = $Submenus
@onready var roster: RosterSelector = $Submenus/Roster
@onready var fast_travel = $Submenus/FastTravel
@onready var crafting = $Submenus/Crafting
var camp_item: ResCampItem
var camp_target: ResPlayerCombatant
var mode: Mode = Mode.CAMP
#var select_guard:bool = false
var guard_combatant: ResPlayerCombatant
var wake_events = [
	'fight',
	'steal',
	'damage',
	'status_effect'
	]
var cam_default_pos:Vector2
var default_roster_pos:Vector2

var selected_pos:int

func _ready():
	modulate = Color.TRANSPARENT
	for combatant in ResourceGlobals.loadArrayFromPath("res://resources/combat/combatants_player/"):
		PlayerGlobals.addCombatantToTeam(combatant)
	default_roster_pos = roster.position
	cam_default_pos = OverworldGlobals.player.player_camera.global_position
	rest_button.disabled = PlayerGlobals.rested and save_point.mind_rested
	fillCampItemContainer()
	#tweenButtons(camp_item_container.get_children())
	#tweenButtons($CampBar/RestOptions.get_children())
	#tweenButtons($CampBar/MainBar/OtherActions.get_children())
	roster.added_character.connect(addRestSprite)
	roster.removed_character.connect(removeRestSprite)
	
	for child in save_point.rest_spots.get_children():
#		if child.texture == null:
#			continue
		var mini_bar: CombatBarsMini = child.get_node('CombatBars')
		#var combatant = mini_bar.attached_combatant
		mini_bar.selector.pressed.connect(
			func():
				if mode == Mode.CAMP and isCampItemValid():
					camp_item.applyEffects(mini_bar.attached_combatant)
					camp_item.take(1)
					updateCombatants()
					pulseButtonActionTexture(mini_bar, camp_item.party_wide)
					if !isCampItemValid():
						setButtonActionTexture(null)
				elif mode == Mode.ROSTER:
					print(selected_pos)
					selected_pos = save_point.rest_spots.get_children().find(mini_bar.get_parent())
					pulseButtonActionTexture(mini_bar,false,false)
					showRoster(mini_bar.attached_combatant)
				elif mode == Mode.SELECT_GUARD:
					if guard_combatant == mini_bar.attached_combatant:
						save_point.showWatchMark(guard_combatant,true)
						guard_combatant = null
					else:
						guard_combatant = mini_bar.attached_combatant
						save_point.showWatchMark(guard_combatant)
					if guard_combatant != null:
						confirm_rest.text = 'REST'
					else:
						confirm_rest.text = 'SKIP GUARD'
		)
		mini_bar.selector.focus_entered.connect(
			func(): 
				if mode == Mode.ROSTER:
					if mini_bar.attached_combatant != null:
						setButtonActionTexture(SWITCH_ROSTER_ICON,mini_bar)
					else:
						setButtonActionTexture(ADD_ROSTER_ICON,mini_bar)
					if roster.visible:
						hideRoster()
				elif mode == Mode.CAMP and isCampItemValid(): 
					setButtonActionTexture(camp_item.icon,mini_bar,camp_item.party_wide)
				)
		mini_bar.selector.focus_exited.connect(func(): setButtonActionTexture(null))
	create_tween().tween_property(self, 'modulate',Color.WHITE,0.5)

func addRestSprite(character: ResPlayerCombatant): 
	save_point.addRestSprite(character,selected_pos)
	hideRoster()

func removeRestSprite(character):
	save_point.removeRestSprite(character)
	hideRoster()
	save_point.showEmptyMembers()

func setButtonActionTexture(texture:Texture,bar: CombatBarsMini=null,party_wide:bool=false):
	if texture == null:
		if party_wide or bar == null:
			for mini_bar in save_point.getCombatBars(true):
				mini_bar.unsetActionTexture()
		else:
			bar.unsetActionTexture()
		return
	
	if bar == null or party_wide:
		for mini_bar in save_point.getCombatBars(true):
			mini_bar.setActionTexture(texture)
	else:
		bar.setActionTexture(texture)

func pulseButtonActionTexture(bar:CombatBarsMini,party_wide:bool=false,reset_view:bool=true):
	if party_wide:
		for mini_bar in save_point.getCombatBars(true):
			mini_bar.pulseActionTexture(reset_view)
	else:
		bar.pulseActionTexture(reset_view)

func updateCombatants():
	for combatant in squad:
		getRestSprite(combatant).get_node('CombatBars').updateStatusEffects()

func isCampItemValid():
	return camp_item != null and camp_item.stack > 0

func _on_eat_pressed():
	#fillCampItemContainer()
	save_point.setBarVisibility(true)
	showContainer(camp_item_container)

func _on_craft_pressed():
	showSubmenu(crafting)

func _on_fast_travel_pressed():
	showSubmenu(fast_travel)

func _on_game_menu_pressed():
	hideSubmenus()
	for bar in save_point.getCombatBars(true): 
		bar.show()
	mode = Mode.ROSTER
	save_point.showEmptyMembers()
	#showRoster()
	#setMainBarVisibility(false)
	#back_button.show()

func showRoster(replace_combatant:ResPlayerCombatant=null):
	roster.loadMembers(replace_combatant)
	roster.show()
	roster.modulate = Color.TRANSPARENT
	save_point.showEmptyMembers()
	roster.position += Vector2(0,64)
	create_tween().tween_property(roster,'position',default_roster_pos,0.2).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(roster,'modulate',Color.WHITE,0.15)

func hideRoster():
	var offset = Vector2(0,64)
	create_tween().tween_property(roster,'position',roster.position+offset,0.1).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(roster,'modulate',Color.TRANSPARENT,0.15)
	#setMainBarVisibility(false)
	await get_tree().create_timer(0.3).timeout
	roster.hide()
#func setButtons(set_to:bool):
#	for button in action_container.get_children():
#		button.visible = set_to

func showSubmenu(menu:Control, hide_bars:bool=true):
	#OverworldGlobals.closeSubmenu()
	save_point.hideEmptyMembers()
	if hide_bars:
		for bar in save_point.getCombatBars(true): bar.hide()
	else:
		for bar in save_point.getCombatBars(true): bar.show()
	
	for sub_menu in sub_menus.get_children():
		sub_menu.visible = menu == sub_menu
	#menu.show()
	#back_button.show()

#	var ui = load(path).instantiate()
#	ui.modulate = Color.TRANSPARENT
#	ui.name = 'Menu'
#	player_ui_path.add_child(ui)
#	ui.position += offset
#	create_tween().tween_property(ui,'position',ui.position-offset,0.25).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CUBIC)
#	create_tween().tween_property(ui,'modulate',Color.WHITE,0.3)
#	back_button.show()

func tweenButtons(buttons: Array):
	for button in buttons:
		button.modulate = Color.TRANSPARENT
	await get_tree().process_frame
	var sound_reducer = 1
	for button in buttons:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.finished.connect(func():OverworldGlobals.playSound('536805__egomassive__gun_2.ogg',-6.0-sound_reducer),CONNECT_ONE_SHOT)
		tween.tween_property(button, 'scale', Vector2(1.1,1.1), 0.5)
		tween.tween_property(button, 'scale', Vector2(1.0,1.0), 0.25)
		tween.set_parallel(true)
		tween.tween_property(button, 'modulate', Color.WHITE, 0.05)
		await get_tree().create_timer(0.05).timeout
		sound_reducer += 0.5
	
	
func showContainer(container):
	for control in get_children().filter(func(control): return control is Container):
		control.hide()
	if container == null:
		return
	container.show()
	OverworldGlobals.setMenuFocus(container)
	#await tweenButtons(container.get_children())

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_show_menu"):
		OverworldGlobals.showMenu("res://scenes/user_interface/GameMenu.tscn",true)
		#hideSubmenus()

func _on_rest_pressed():
	action_bar.hide()
	hideSubmenus()
	OverworldGlobals.moveCamera(save_point,0.5, Vector2(0,-30))
	save_point.setBarVisibility(true)
	mode = Mode.SELECT_GUARD
	rest_ui.show()

func hideSubmenus():
	for menu in sub_menus.get_children():
		menu.hide()

func _on_confirm_rest_pressed():
	#setMainBarVisibility(false)
	hide()
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

func fillCampItemContainer(clear_previous:bool=false):
	if clear_previous:
		camp_item = null
		for item in camp_item_container.get_children():
			item.queue_free()
		await get_tree().process_frame
	for item in getCampItems():
#		if item == null or item.icoon == null: #temp
#			continue
		var button = OverworldGlobals.createItemButton(item)
		button.pressed.connect(
			func():
				camp_item = item
				piss(Color(Color.DARK_GRAY, 0.5))
				button.modulate = Color.WHITE
				#unhighlightAll()
				)
		#button.description_offset=Vector2(0,116)
		camp_item_container.add_child(button)

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
#	action_container.hide()
	#setMainBarVisibility(false)
	hide()
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 0.5)
	#await get_tree().create_timer(1.5).timeout
	save_point.done.emit()
	queue_free()


func _on_camp_pressed():
	fillCampItemContainer(true)
	mode = Mode.CAMP
	showSubmenu(camping,false)
	await get_tree().create_timer(0.5).timeout


func _on_return_pressed():
	rest_ui.hide()
	OverworldGlobals.moveCamera(cam_default_pos,0.5)
	if guard_combatant != null:
		save_point.showWatchMark(guard_combatant, true)
		guard_combatant = null
	action_bar.show()
	showSubmenu(camping)
