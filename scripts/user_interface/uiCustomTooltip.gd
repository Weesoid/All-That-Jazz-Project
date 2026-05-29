extends PanelContainer
class_name CustomTooltip

const SPACING = 8
enum AnchorPreset {
	RIGHT,
	LEFT,
	TOP,
	BOTTOM
}
@onready var text_label = $RichTextLabel
@onready var animator = $AnimationPlayer

@export_multiline var text = ''
@export var tooltip_position: AnchorPreset = AnchorPreset.RIGHT
@export var show_on_hover:bool=true
#@export var show_on_hover:bool=true

func _ready():
	var parent = get_parent_control()
	if show_on_hover:
		#parent.hovere
		parent.focus_entered.connect(showTooltip)
		parent.mouse_entered.connect(showTooltip)
		set_process_input(false)
	parent.focus_exited.connect(hideTooltip)
	parent.mouse_exited.connect(hideTooltip)
	hide()
	hideTooltip()
	if text != '':
		setText(text)

func _input(event):
	if Input.is_action_pressed('ui_show_info') and get_parent_control().has_focus():
		showTooltip()
	if Input.is_action_just_released('ui_show_info'):
		hideTooltip()

func showTooltip():
	show()
	animator.play("Show")
	await get_tree().process_frame
	setAnchor()
	#await animator.animation_finished

func hideTooltip():
	animator.play_backwards("Show")
	await animator.animation_finished
	hide()

func setText(text:String):
	text_label.text = text.strip_edges()
	await text_label.resized
	await get_tree().process_frame
	setAnchor()

func setAnchor():
	var parent = get_parent_control()
	var offset
	
	match tooltip_position:
		AnchorPreset.RIGHT: offset = Vector2(parent.size.x+SPACING,0)
		AnchorPreset.LEFT: offset = Vector2(-size.x-SPACING,0)
		AnchorPreset.TOP: offset = Vector2(-size.x/3.25,-size.y-SPACING)
		AnchorPreset.BOTTOM: offset = Vector2(-size.x/3.25,parent.size.y+SPACING)
	
	global_position = parent.global_position + offset
