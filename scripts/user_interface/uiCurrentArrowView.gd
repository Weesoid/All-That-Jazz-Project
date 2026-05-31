extends Container
class_name CurrentArrowView

func _ready():
	await get_tree().process_frame
	OverworldGlobals.player.bow_equipped.connect(updateArrowIndicator)
	OverworldGlobals.player.bow_equipped.connect(changeOpacity.bind(2))
	OverworldGlobals.player.bow_shot.connect(changeOpacity.bind(2))
	OverworldGlobals.player.bow_undrawn.connect(changeOpacity.bind(2))
	OverworldGlobals.player.bow_drawn.connect(changeOpacity.bind(1))
	OverworldGlobals.player.bow_unequipped.connect(changeOpacity.bind(3))
	updateArrowIndicator()

func updateArrowIndicator():
	if PlayerGlobals.equipped_arrow == null:
		return
	
	if get_child_count() == 0:
		addArrowCounter()
	else:
		var arrow_button = get_children()[0]
		if arrow_button.item != PlayerGlobals.equipped_arrow:
			arrow_button.queue_free()
			addArrowCounter()

func addArrowCounter():
	var arrow_button = UIGlobals.createItemButton(PlayerGlobals.equipped_arrow)
	var count_label = getCountLabel(arrow_button)
	arrow_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
	arrow_button.focus_mode=Control.FOCUS_NONE
	arrow_button.flat = true
	count_label.position += Vector2(8,2)
	add_child(arrow_button)

func getCountLabel(button):
	for child in button.get_children():
		if child is StackCountLabel: return child
	return null

func changeOpacity(change_to:int):
	match change_to:
		1:get_tree().create_tween().tween_property(self,'modulate',Color.WHITE,0.25)
		2:get_tree().create_tween().tween_property(self,'modulate',Color(Color.WHITE,0.5),0.25)
		3:get_tree().create_tween().tween_property(self,'modulate',Color.TRANSPARENT,0.25)
