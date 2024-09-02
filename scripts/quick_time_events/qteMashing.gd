extends Node2D

@onready var ding_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var timer = $Timer
@onready var bar = $MashBar
@onready var time_bar = $TimeBar
@onready var animator = $AnimationPlayer

var time
var drain_speed = 10.0
var mash_strength = 15.0
var max_ponts = 1
var points = 0

func _ready():
	randomize()
	bar.max_value = 100
	bar.value = 0
	time = (max_ponts * 4) - randf_range(2.0, 3.0)
	time_bar.max_value = time
	timer.start(time)

func _physics_process(delta):
	time_bar.value = timer.time_left
	if bar.value != 0:
		bar.value -= 0.05
	if bar.value >= 99:
		bar.value = 0
		points += 1
		OverworldGlobals.playSound('542003__rob_marion__gasp_lock-and-load.ogg', 0.0, 1.0 + (0.005 * points), false)
		animator.play("Point")
		if points == max_ponts:
			OverworldGlobals.playSound('542003__rob_marion__gasp_lock-and-load.ogg', 0.0, 1.0 + (0.5 * points), false)
			time_bar.hide()
			bar.hide()
			CombatGlobals.qte_finished.emit()
		else:
			newMash()

func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_accept"):
		ding_sound.pitch_scale += (0.025 * points)
		ding_sound.play()
		bar.value += mash_strength

func newMash():
	randomize()
	mash_strength -= randf_range(.0, 2.0)

func _on_timer_timeout():
	OverworldGlobals.playSound("542041__rob_marion__gasp_weapon-slash_1.ogg")
	CombatGlobals.qte_finished.emit()
