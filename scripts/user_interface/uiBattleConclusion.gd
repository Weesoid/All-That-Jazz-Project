extends Control

@onready var drop_text = $RichTextLabel
@onready var animator = $AnimationPlayer
@onready var exp_bar = $PartyExp
@onready var audio_player = $AudioStreamPlayer
 
var drops = ''
signal done

func _ready():
	drop_text.text += drops
	animator.play("Show")
	audio_player.play()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_accept") and !animator.is_playing():
		done.emit()
