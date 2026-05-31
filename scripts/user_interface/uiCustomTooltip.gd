extends PanelContainer
class_name CustomTooltip

enum AnchorPreset {
	RIGHT,
	LEFT,
	TOP,
	BOTTOM
}
enum TextAlignment {
	LEFT,
	RIGHT,
	CENTER
}
@onready var text_label = $RichTextLabel
@onready var animator = $AnimationPlayer
@onready var show_delay_timer = $ShowDelay

@export_multiline var text = ''
@export var text_alignment: TextAlignment = TextAlignment.LEFT
@export var tooltip_position: AnchorPreset = AnchorPreset.RIGHT
@export var show_on_hover:bool=true
@export var spacing = 8
@export var show_delay:float = 0.0
@export var shrink: bool=false
#@export var show_on_hover:bool=true

func _ready():
	setShowHover(show_on_hover)
	hide()
	hideTooltip()
	if text != '':
		setText(text)
	show_delay_timer.stop()

func setShowHover(set_to:bool):
	show_on_hover = set_to
	var parent = get_parent_control()
	if set_to:
		if !parent.focus_entered.is_connected(showTooltip):
			parent.focus_entered.connect(showTooltip)
#		if !parent.mouse_entered.is_connected(showTooltip):
#			parent.mouse_entered.connect(showTooltip)
		set_process_input(false)
	else:
		if parent.focus_entered.is_connected(showTooltip):
			parent.focus_entered.disconnect(showTooltip)
#		if parent.mouse_entered.is_connected(showTooltip):
#			parent.mouse_entered.disconnect(showTooltip)
		set_process_input(true)
	
	if !parent.focus_exited.is_connected(hideTooltip):
		parent.focus_exited.connect(hideTooltip)
	if !parent.mouse_exited.is_connected(hideTooltip):
		parent.mouse_exited.connect(hideTooltip)

func _input(event):
	if Input.is_action_pressed('ui_show_info') and get_parent_control().has_focus():
		showTooltip()
	if Input.is_action_just_released('ui_show_info'):
		hideTooltip()

func showTooltip():
	if show_delay_timer.is_stopped() and show_delay > 0.0:
		show_delay_timer.start(show_delay)
	else:
		_on_show_delay_timeout()

func hideTooltip():
	if !show_delay_timer.is_stopped() and show_delay > 0.0:
		show_delay_timer.stop()
		return
	
	animator.play_backwards("Show")
	await animator.animation_finished
	hide()

func setText(text:String):
	var alignment
	match text_alignment:
		TextAlignment.RIGHT: alignment = '[right]'
		TextAlignment.LEFT: alignment = '[left]'
		TextAlignment.CENTER: alignment = '[center]'
	
	text_label.text = alignment+text.strip_edges()
	await text_label.resized
	await get_tree().process_frame
	setAnchor()

func setAnchor():
	if shrink:
		size = Vector2(0,0)
		text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var parent = get_parent_control()
	var offset
	
	match tooltip_position:
		AnchorPreset.RIGHT: offset = Vector2(parent.size.x+spacing,0)
		AnchorPreset.LEFT: offset = Vector2(-size.x-spacing,0)
		AnchorPreset.TOP: offset = Vector2(-size.x/2.5,-size.y-spacing)
		AnchorPreset.BOTTOM: offset = Vector2(-size.x/2.5,parent.size.y+spacing)
	
	global_position = parent.global_position + offset
	
#	if shrink and (anchors_preset==AnchorPreset.TOP or anchors_preset==AnchorPreset.BOTTOM):
#		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
#	elif shrink and anchors_preset == AnchorPreset.RIGHT:
#		print('shrunk right')
#		size_flags_horizontal = Control.SIZE_SHRINK_END
#	elif shrink and anchors_preset == AnchorPreset.LEFT:
#		print('shrunk left')
#		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func _on_show_delay_timeout():
	show()
	animator.play("Show")
	await get_tree().process_frame
	setAnchor()
