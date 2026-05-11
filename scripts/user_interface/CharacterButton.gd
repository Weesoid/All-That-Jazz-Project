extends CustomDragDropButton
class_name CharacterButton

@onready var bar = $Bar
@export var combatant: ResPlayerCombatant
@export var focus_pos_offset = Vector2(0,6)
var initial_bar_pos:Vector2
var tween_running:bool=false
signal character_presssed(character)

func ready():
	await get_tree().process_frame
	initial_bar_pos = bar.position
	bar.setCharacter(combatant)

func playFocusMotions(focused:bool):
	tween_running=true
	var tween = create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT)
	if focused:
		tween.tween_property(bar, 'position', initial_bar_pos-focus_pos_offset,0.1)
		tween.tween_property(bar, 'modulate', Color.YELLOW,0.25)
	else:
		tween.tween_property(bar, 'position', initial_bar_pos,0.1)
		tween.tween_property(bar, 'modulate', Color.WHITE,0.25)

func getPreview():
	var preview = Control.new()
	var dupe_bar = bar.duplicate()
	dupe_bar.modulate = Color.WHITE
	preview.size = size
	preview.z_index=4000
	preview.add_child(dupe_bar)
	dupe_bar.position -= preview.size/2
	print(dupe_bar.position)
	return preview

func _get_drag_data(at_position):
	set_drag_preview(getPreview())
	return self

func _on_focus_entered_bar_motion():
	#pass
	playFocusMotions(true)

func _on_focus_exited_bar_motion():
	#pass
	playFocusMotions(false)

func _on_pressed_emit_combatant():
	print(combatant)
	character_presssed.emit(combatant)

func _enter_tree():
	#if bar != null
	#initial_bar_pos = bar.position
	#print(position)
	pass
	#await get_tree().process_frame
	#initial_bar_pos = position

func initializeBar():
	pass
	#bar.

