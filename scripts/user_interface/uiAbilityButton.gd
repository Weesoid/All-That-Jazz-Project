extends CustomButton
class_name CustomAbilityButton

@onready var ability_icon = $TextureRect
@onready var icon_animator = $TextureRect/AnimationPlayer
@onready var description_label = $PanelContainer/RichTextLabel
@onready var description_panel = $PanelContainer
@onready var description_animator = $PanelContainer/AnimationPlayer
@onready var charges = $TextureRect/Charges
@onready var lock_icon = $TextureRect/LockIcon
@onready var ability_cost = $TextureRect/LockIcon/LockIcon/Label

@export var ability: ResAbility
@export var descriptions: Dictionary = {
	'title': '',
	'description': '',
	'icon': preload("res://images/ability_icons/default.png")
}
@export var custom_charge: int = -1
@export var outside_combat: bool = false
var default_modulate:Color = Color.WHITE
var focused_modulate:Color = Color.YELLOW

var is_locked:bool=false

func _ready():
	$TextureRect/HoldProgress.modulate=hold_color
	if ability != null:
		ability_icon.texture = ability.icon
		description_label.text = ability.getRichDescription(true)
		description_panel.hide()
		if custom_charge > -1:
			charges.text = str(custom_charge)
			charges.show()
		elif ability.charges > 0:
			if !outside_combat:
				charges.text = str(CombatGlobals.getCombatScene().getChargesLeft(CombatGlobals.getCombatScene().active_combatant, ability))
			else:
				charges.text = str(ability.charges)
			charges.show()
		if disabled:
			ability_icon.modulate = Color.DIM_GRAY
		if outside_combat:
			custom_minimum_size = Vector2(48,48)
			ability_icon.set_deferred('size', Vector2(24,24))
			ability_icon.set_anchors_preset(Control.PRESET_CENTER)
			tooltip.tooltip_position = CustomTooltip.AnchorPreset.RIGHT
			tooltip.spacing = 8
			tooltip.setShowHover(true)
		tooltip.setText(ability.getRichDescription())
	else:
		description_label.text = descriptions['title'].to_upper()+'\n'+descriptions['description']
		ability_icon.texture = descriptions['icon']
		tooltip.queue_free()

func setLocked(set_to:bool):
	is_locked = set_to
	if set_to:
		default_modulate = Color.DIM_GRAY
		focused_modulate = Color.DIM_GRAY
		ability_icon.self_modulate = default_modulate
		lock_icon.show()
	else:
		default_modulate = Color.WHITE
		focused_modulate = Color.YELLOW
		ability_icon.self_modulate = default_modulate
		lock_icon.hide()

func setCost(combatant:ResCombatant):
	ability_cost.text = str(PlayerGlobals.getAbilityCost(combatant, ability))

func setDisabled(set_to:bool):
	if set_to:
		dimButton()
		disabled=true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
	else:
		undimButton()
		disabled=false
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL

func _on_pressed():
	press_feedback()
	icon_animator.play('Pressed')

func _on_focus_entered():
	focus_feedback()

func _on_mouse_entered():
	focus_feedback()
	if focus_mode != Control.FOCUS_NONE:
		grab_focus()

func _on_mouse_exited():
	exit_focus_feedback()

func _on_focus_exited():
	exit_focus_feedback()

func dimButton():
	if ability_icon != null:
		ability_icon.modulate = Color.DIM_GRAY

func undimButton():
	if ability_icon != null:
		ability_icon.modulate = default_modulate

func _on_visibility_changed():
	if ability_icon != null:
		ability_icon.self_modulate = default_modulate

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	
	z_index = 99
	if outside_combat:
		ability_icon.self_modulate = focused_modulate
	else:
		icon_animator.play("Focus")
	lock_icon.scale = Vector2(1.5,1.5)

func exit_focus_feedback():
	delay_timer.stop()
	if hold_time > 0 and audio_player.stream == hold_sound:
		hold_timer.stop()
		audio_player.stop()
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()
	z_index = 0
	if !is_locked:
		icon_animator.play('RESET')
	else:
		ability_icon.self_modulate = default_modulate
	if description_panel.visible: 
		hideDescription()
	lock_icon.scale = Vector2(1,1)
	hideDescription()
