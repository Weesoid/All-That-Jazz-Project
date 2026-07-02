extends Container
class_name CurrentArrowView

@onready var arrow_counter: ItemButton = $ItemButton

func _ready():
	await get_tree().process_frame
	OverworldGlobals.player.bow_equipped.connect(updateArrowIndicator)
	OverworldGlobals.player.bow_equipped.connect(changeOpacity.bind(2))
	OverworldGlobals.player.bow_shot.connect(changeOpacity.bind(2))
	OverworldGlobals.player.bow_undrawn.connect(changeOpacity.bind(2))
	OverworldGlobals.player.bow_drawn.connect(changeOpacity.bind(1))
	OverworldGlobals.player.bow_unequipped.connect(changeOpacity.bind(3))

func updateArrowIndicator():
	if PlayerGlobals.equipped_arrow == null:
		return
	arrow_counter.setItem(PlayerGlobals.equipped_arrow)

func getCountLabel(button):
	for child in button.get_children():
		if child is StackCountLabel: return child
	return null

func changeOpacity(change_to:int):
	match change_to:
		1:get_tree().create_tween().tween_property(self,'modulate',Color.WHITE,0.25)
		2:get_tree().create_tween().tween_property(self,'modulate',Color(Color.WHITE,0.5),0.25)
		3:get_tree().create_tween().tween_property(self,'modulate',Color.TRANSPARENT,0.25)

func canShow():
	return OverworldGlobals.player.bow_mode
