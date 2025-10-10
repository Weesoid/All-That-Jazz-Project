extends Button
class_name CustomButton

@onready var audio_player = $AudioStreamPlayer
@onready var hold_timer = $HoldTimer
@onready var delay_timer = $HoldDelay

@export var description_text: String
@export var description_offset: Vector2= Vector2.ZERO
@export var focused_entered_sound: AudioStream = preload("res://audio/sounds/421465__jaszunio15__click_5.ogg")
@export var click_sound: AudioStream = preload("res://audio/sounds/421469__jaszunio15__click_149.ogg")
@export var hold_sound: AudioStream = preload("res://audio/sounds/loading sfx loopable.ogg")
@export var hold_color:Color=Color.YELLOW
@export var hold_key: Array[String] = ["ui_accept","ui_click"]
@export var hold_time:float = -1
@export var hold_delay:float=0.25

var random_pitch = 0.1

signal held_press
signal hold_started

func _ready():
	$HoldProgress.modulate=hold_color

func _on_focus_entered():
	focus_feedback()
	if Input.is_action_pressed("ui_select_arrow") and description_text != '':
		showDescription()

func _on_pressed():
	press_feedback()

func _on_mouse_entered():
	if Input.is_action_pressed("ui_select_arrow") and description_text != '':
		showDescription()
	grab_focus()

func _on_mouse_exited():
	exit_focus_feedback()

func _on_focus_exited():
	exit_focus_feedback()

func _input(_event):
	if Input.is_action_just_pressed("ui_select_arrow") and has_focus() and description_text != '':
		showDescription()
	checkHoldInputs()

func showDescription():
	var side_description = load("res://scenes/user_interface/ButtonDescription.tscn").instantiate()
	add_child(side_description)
	side_description.showDescription(description_text, description_offset)

func checkHoldInputs():
	if disabled:
		return
	
	if isHoldKey('pressed') and has_focus() and hold_time > 0:
		delay_timer.start(hold_delay)
		await delay_timer.timeout
		await cancelPress()
		audio_player.stop()
		audio_player.stream = hold_sound
		audio_player.play()
		hold_timer.start(hold_time)
		hold_started.emit()
	if isHoldKey('released') and !delay_timer.is_stopped():
		delay_timer.stop()
	if !hold_timer.is_stopped() and (isHoldKey('released') or Input.is_action_just_pressed("ui_alt_cancel")) and has_focus():
		if Input.is_action_just_pressed("ui_alt_cancel") and has_focus():
			await cancelPress()
		delay_timer.stop()
		audio_player.stop()
		hold_timer.stop()

func isHoldKey(action:String):
	for input in hold_key:
		if action == 'pressed' and Input.is_action_just_pressed(input):
			return true
		elif action == 'released' and Input.is_action_just_released(input):
			return true
	return false

func _on_hold_timer_timeout():
	if has_focus(): await cancelPress()
	press_feedback()
	held_press.emit()

func cancelPress():
	if !delay_timer.is_stopped():
		delay_timer.stop()
	set_block_signals(true)
	release_focus()
	await get_tree().process_frame
	grab_focus()
	set_block_signals(false)

func press_feedback():
	if click_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()

func exit_focus_feedback():
	delay_timer.stop()
	if hold_time > 0 and audio_player.stream == hold_sound:
		hold_timer.stop()
		audio_player.stop()
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()
