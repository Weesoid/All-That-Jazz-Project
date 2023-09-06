extends Node2D

@onready var ding_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var timer = $Timer
@onready var bar = $MashBar
@onready var time_bar = $TimeBar
@onready var animator = $AnimationPlayer

var time
var drain_speed = 2.0
var mash_strength = 10.0
var max_ponts = 3
var points = 0

func _ready():
	randomize()
	bar.max_value = 100
	bar.value = 0
	time = (max_ponts * 3) - randf_range(2.0, 3.0)
	time_bar.max_value = time
	timer.start(time)

func _process(delta):
	time_bar.value = timer.time_left
	if bar.value != 0:
		bar.value -= 0.05
	if bar.value >= 99:
		bar.value = 0
		points += 1
		ding_sound.pitch_scale += (0.1 * points)
		ding_sound.play()
		animator.play("Point")
		if points == max_ponts:
			ding_sound.volume_db += 0.5
			time_bar.hide()
			bar.hide()
			await ding_sound.finished
			print('Finished with points: ', points)
			CombatGlobals.qte_finished.emit()
		else:
			newMash()

func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_accept"):
		bar.value += mash_strength

func newMash():
	randomize()
	mash_strength -= randf_range(1.0, 2.0)

func _on_timer_timeout():
	CombatGlobals.qte_finished.emit()
