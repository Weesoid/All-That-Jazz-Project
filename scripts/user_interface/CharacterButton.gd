extends CustomDragDropButton
class_name CharacterButton

enum FocusMotion {
	UP,
	LEFT
}

@onready var bar = $Bar
@export var combatant: ResPlayerCombatant
@export var focus_pos_offset = Vector2(0,6)
@export var focus_motion: FocusMotion = FocusMotion.UP
@export var controller_click_to_drag:bool=false
var initial_bar_pos:Vector2
var tween_running:bool=false
signal character_presssed(character)
signal drag_start

func _ready():
	$HoldProgress.modulate = hold_color
	setTooltip()
	match focus_motion:
		FocusMotion.UP: focus_pos_offset = Vector2(0,6)
		FocusMotion.LEFT: focus_pos_offset = Vector2(6,0)
	if controller_click_to_drag:
		held_press.disconnect(_on_held_press)
		pressed.connect(_on_held_press)
		hold_time = -1
	await get_tree().process_frame
	initial_bar_pos = bar.position
	bar.setCharacter(combatant)

func setCombatant(p_combatant: ResCombatant):
	combatant = p_combatant
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

func _get_drag_data(_at_position):
	set_drag_preview(getPreview())
	drag_start.emit()
	return self

func _on_focus_entered_bar_motion():
	playFocusMotions(true)

func _on_focus_exited_bar_motion():
	playFocusMotions(false)

func _on_pressed_emit_combatant():
	character_presssed.emit(combatant)

func _on_held_press():
	if UIGlobals.isUsingController():
		force_drag(self, getPreview())
		drag_start.emit()

func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN and get_viewport().gui_get_drag_data() == self:
		modulate = Color(Color.WHITE, 0.5)
	if what == NOTIFICATION_DRAG_END:
		modulate = Color.WHITE
