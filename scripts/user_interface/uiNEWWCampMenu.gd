extends Control

@onready var inventory: MiniInventory = $MiniInventory
@onready var crafting: CraftingMenu = $uiCrafting
var camp_bars
var original_positions: Dictionary
#var inventory_starting_pos:Vector2
#var inventory_offscreen_pos:Vector2
var done:bool=false

func _ready():
	camp_bars = OverworldGlobals.player.current_camp_spot.getCampBars()
	for bar in camp_bars:
		bar.camp_button.party_wide_item_hovered.connect(showPartyItem)
		bar.camp_button.mouse_exited.connect(hideAllItems)
	
	inventory.showItems()
	original_positions[crafting] = crafting.position
	setMenVis(crafting, original_positions[crafting],false)
#	inventory_starting_pos = inventory.position
#	inventory_offscreen_pos = inventory_starting_pos+Vector2(64,0)
	inventory.drop_detector.item_dropped.connect(clearPartyItem)
	inventory.drop_detector.item_dropped.connect(updateStrainBars)
	setMenuVisibility(false)
	await get_tree().create_timer(1.75).timeout
	setMenuVisibility(true)
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

func setMenuVisibility(set_to:bool):
	var tween = create_tween()
	if set_to:
		tween.tween_property(self,'modulate',Color.WHITE,0.5)
	else:
		tween.tween_property(self,'modulate',Color.TRANSPARENT,0.5)

func setMenVis(menu:Control, pos:Vector2, set_to:bool):
	var tween = create_tween().set_parallel()
	var offscreen_pos = pos + Vector2(128,0)
	if set_to:
		menu.show()
		tween.tween_property(menu,'modulate',Color.WHITE,0.25)
		tween.tween_property(menu,'position',pos,0.25)
	else:
		tween.tween_property(menu,'modulate',Color.TRANSPARENT,0.25)
		tween.tween_property(menu,'position',offscreen_pos,0.25)
		await tween.finished
		menu.hide()

func _on_crafting_pressed():
	crafting.resetCrafting()
	setMenVis(crafting, original_positions[crafting], crafting.position != original_positions[crafting])
