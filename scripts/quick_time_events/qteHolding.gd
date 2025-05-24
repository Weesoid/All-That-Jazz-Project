extends Node2D

var sweet_spot
var goal_scale = Vector2(1.0, 1.0)
var scale_penalty = 0.1
var base_penalty = 4.0
var shrink = false
var target_speed = 2.5
var max_points = 1
var points = 0

@onready var target = $HoldCircle
@onready var target_sprite = $HoldCircle.get_node('Sprite2D')
@onready var ding_sound = $AudioStreamPlayer2D
@onready var timer = $Timer
@onready var animator = $AnimationPlayer

func _ready():
	Input.action_release('ui_accept')
	animator.play("RotateLoop")
	newSweetSpot()

func _process(delta):
	if !timer.is_stopped():
		target.get_node('Sprite2D').modulate.a = timer.time_left
	if shrink:
		target.scale -= Vector2(1, 1) * target_speed * delta
	if sweet_spot != null and target.scale <= sweet_spot.scale:
		sweet_spot.modulate = Color.GREEN_YELLOW
	else:
		sweet_spot.modulate = Color.WHITE
	if target.scale <= Vector2.ZERO:
		shrink = false
		OverworldGlobals.playSound("542041__rob_marion__gasp_weapon-slash_1.ogg")
		CombatGlobals.qte_finished.emit()

func _unhandled_input(_event):
	if Input.is_action_pressed("ui_accept"):
		target.get_node('Sprite2D').modulate.a = 1.0
		timer.stop()
		shrink = true
	if Input.is_action_just_released("ui_accept"):
		shrink = false
		if target.scale <= sweet_spot.scale:
			OverworldGlobals.playSound("res://audio/sounds/542003__rob_marion__gasp_lock-and-load.ogg", 0.0, 1.0 + (0.025 * points))
			points += 1
			sweet_spot.queue_free()
			if points == max_points:
				CombatGlobals.qte_finished.emit()
			else:
				target.scale = Vector2(1.0, 1.0)
				randomize()
				target_speed += randf_range(0.1, 0.5)
				newSweetSpot()
		else:
			OverworldGlobals.playSound("542041__rob_marion__gasp_weapon-slash_1.ogg")
			CombatGlobals.qte_finished.emit()

func resetTarget():
	target.scale = Vector2(1.0, 1.0)

func newSweetSpot():
	sweet_spot = preload("res://scenes/quick_time_events/targets/HoldingTarget.tscn").instantiate()
	sweet_spot.scale -= Vector2(scale_penalty, scale_penalty) * (base_penalty + points)
	add_child(sweet_spot)
	timer.start(1.0)


func _on_timer_timeout():
	OverworldGlobals.playSound("542041__rob_marion__gasp_weapon-slash_1.ogg")
	CombatGlobals.qte_finished.emit()
