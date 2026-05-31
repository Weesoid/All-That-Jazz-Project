extends Control
class_name CampMenu

const INV_ICON = preload("res://images/sprites/sack_inverted.png")
const FAST_TRAVEL_ICON = preload("res://images/sprites/button_pinpoint_normal.png")

@onready var inventory: MiniInventory = $MiniInventory
@onready var crafting: CraftingMenu = $uiCrafting
@onready var fast_travel = $FastTravel
@onready var fast_travel_button = $HBoxContainer/FastTravel
@onready var crafting_button = $HBoxContainer/Crafting
@onready var buttons = $HBoxContainer
@onready var gradient = $TextureRect
@onready var guard_label = $Label
@onready var rest_options = $RestOptions
@onready var rest_button = $HBoxContainer/Rest
#@onready var ambush_label = $Sprite2D
var camp_bars
var original_positions: Dictionary
var guard_combatant:ResPlayerCombatant
var rest_mode:bool=false
var done:bool=false

func _ready():
	modulate=Color.TRANSPARENT
	camp_bars = OverworldGlobals.player.current_camp_spot.getCampBars()
	for bar in camp_bars:
		bar.camp_button.party_wide_item_hovered.connect(showPartyItem)
		bar.camp_button.mouse_exited.connect(hideAllItems)
		bar.camp_button.pressed.connect(func(): setGuard(bar))
	inventory.showItems()
	original_positions[crafting] = crafting.position
	original_positions[inventory] = inventory.position
	original_positions[fast_travel] = fast_travel.position
	original_positions[buttons] = buttons.position
	original_positions[gradient] = gradient.position
	original_positions[guard_label] = guard_label.position
	original_positions[rest_options] = rest_options.position
	setMenuVisibility(crafting, false)
	setMenuVisibility(fast_travel, false)
	setMenuVisibility(guard_label,false,true)
	setMenuVisibility(rest_options,false,true,0.5,true)
	#inventory.drop_detector.item_dropped.connect(clearPartyItem)
	#inventory.drop_detector.item_dropped.connect(updateStrainBars)
	rest_button.setDisabled(true)
	setFullMenuVisibility(false)
	OverworldGlobals.player.current_camp_spot.camp_kindled.connect(func():rest_button.setDisabled(false))
	await get_tree().create_timer(0.25).timeout
	setFullMenuVisibility(true)
	done=true

func restockItem(item: ResStackItem):
	if item.stack > 0: inventory.addButton(item)

func showPartyItem(item: ResCampItem):
	for bar in camp_bars:
		if bar.attached_combatant != null: bar.camp_button.showAction(item)

# DUCT TAPE
func _process(delta):
	if !done:
		modulate = Color.TRANSPARENT

func clearPartyItem(item: ResCampItem):
	if !item.party_wide:
		return
	hideAllItems()

func hideAllItems():
	for bar in camp_bars:
		if bar.attached_combatant != null: bar.camp_button.showAction(null)

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
	setMenuVisibility(buttons, set_to)
	setMenuVisibility(gradient, set_to)
	if entire_menu:
		setMenuVisibility(fast_travel, set_to)
		setMenuVisibility(crafting, set_to)

func _on_crafting_pressed():
	#setMenuVisibility(fast_travel,false)
	#setMenuVisibility(inventory,true)
	if fast_travel.visible:
		fast_travel_button.pressed.emit()
	
	crafting.resetCrafting()
	setMenuVisibility(crafting, crafting.position != original_positions[crafting])


func _on_fast_travel_pressed():
	if crafting.visible:
		crafting_button.pressed.emit()
	setMenuVisibility(inventory, fast_travel.position == original_positions[fast_travel])
	await setMenuVisibility(fast_travel, fast_travel.position != original_positions[fast_travel])
	if fast_travel.visible:
		fast_travel_button.setTexture(INV_ICON)
		fast_travel_button.description_text = '[center]INVENTORY'
	else:
		fast_travel_button.setTexture(FAST_TRAVEL_ICON)
		fast_travel_button.description_text = '[center]FAST TRAVEL'

func setGuard(bar:CombatBarsMini):
	if !rest_mode:
		return
	for other_bar in camp_bars:
		other_bar.setWatchmark(false)
	if bar == null:
		guard_combatant=null
		return
	
	if bar.attached_combatant == guard_combatant:
		guard_combatant = null
		bar.setWatchmark(false)
	else:
		guard_combatant = bar.attached_combatant
		bar.setWatchmark(true)

func _on_rest_held_press():
	OverworldGlobals.player.current_camp_spot.setCamToRestPos()
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
		OverworldGlobals.player.current_camp_spot.fightCombatantSquad()
		await OverworldGlobals.combat_enetered
		OverworldGlobals.player.player_camera.hideOverlay(0.1)
		await OverworldGlobals.combat_exited
#	else:
	doExitTransition(false)

func restCombatant(combatant: ResPlayerCombatant):
	randomize()
	var random_stat_boost= ['speed', 'damage', 'resolve'].pick_random()
	combatant.addTemporaryModifer('Well Rested',3,{'resist':0.1,random_stat_boost:1,'health':5},false,true)
	CombatGlobals.calculateHealing(combatant, ceil(combatant.getMaxHealth()*0.05),false)
	CombatGlobals.healResolve(combatant,3)
	CombatGlobals.removeInjury(combatant,0.1,randi_range(1,2))

func _on_return_pressed():
	setGuard(null)
	rest_mode=false
	OverworldGlobals.player.current_camp_spot.setCamToMenuPos()
	setMenuVisibility(guard_label,false,true,0.5)
	setMenuVisibility(rest_options,false,true,0.5,true)
	setBaseMenuVisibility(true,false)

func _on_embark_held_press():
	doExitTransition()

func doExitTransition(do_screen_fade:bool=true):
	if do_screen_fade: await doScreenFade()
	#await get_tree().process_frame
	setGuard(null)
	OverworldGlobals.player.current_camp_spot.done.emit()
	queue_free()

func doScreenFade():
	setBaseMenuVisibility(false)
	await setFullMenuVisibility(false)
	await OverworldGlobals.player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	await get_tree().create_timer(1.0).timeout
