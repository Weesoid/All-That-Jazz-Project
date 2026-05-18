extends Control
class_name PlayerUI

@onready var save_indicator_animator = $Control/SaveIndicator/AnimationPlayer
@onready var equipped_arrow_container = $ArrowContainer
@onready var player_prompt: = $PlayerPrompt

func _ready():
	await get_tree().process_frame
	
	SaveLoadGlobals.done_saving.connect(showSaveIndicator)


func showSaveIndicator():
	if save_indicator_animator.is_playing():
		return
	
	save_indicator_animator.play("Show")
	await save_indicator_animator.animation_finished
	save_indicator_animator.play_backwards("Show")

func updateArrowIndicator():
	if equipped_arrow_container.get_child_count() == 0:
		addArrowCounter()
	else:
		var arrow_button = equipped_arrow_container.get_children()[0]
		if arrow_button.item != PlayerGlobals.equipped_arrow:
			arrow_button.queue_free()
			addArrowCounter()

func addArrowCounter():
	var arrow_button = OverworldGlobals.createItemButton(PlayerGlobals.equipped_arrow)
	var count_label = getCountLabel(arrow_button)
	arrow_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
	arrow_button.focus_mode=Control.FOCUS_NONE
	arrow_button.flat = true
	count_label.position += Vector2(8,2)
	equipped_arrow_container.add_child(arrow_button)

func getCountLabel(button):
	for child in button.get_children():
		if child is StackCountLabel: return child
	return null
