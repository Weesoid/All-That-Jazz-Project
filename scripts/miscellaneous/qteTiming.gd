extends Node2D

@onready var target: Area2D = $TimingTarget
@onready var ding_sound: AudioStreamPlayer2D = $TimingTarget/AudioStreamPlayer2D
@onready var bar = $TimingBar

var size = 150
var target_speed = 2.0
var max_ponts = 4
var points = 0
var size_penalty = 0.15

func _ready():
	newGoal(true)


func _process(delta):
	moveTarget(delta)

func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_accept"):
		if target.has_overlapping_areas():
			target.get_overlapping_areas()[0].queue_free()
			randomize()
			target_speed += randf_range(0.25, 0.5)
			points += 1
			size*=-1
			ding_sound.pitch_scale += (0.025 * points)
			ding_sound.play()
			if points == max_ponts:
				print('max!')
				ding_sound.volume_db += 0.5
				target.hide()
				await ding_sound.finished
				CombatGlobals.qte_finished.emit()
			newGoal()
		else:
			CombatGlobals.qte_finished.emit()

func moveTarget(d):
	target.global_position = lerp(target.global_position, target.global_position+Vector2(size,0), target_speed * d)
	if size > 0:
		if target.position.x >= size: CombatGlobals.qte_finished.emit()
	elif size < 0:
		if target.position.x <= size: CombatGlobals.qte_finished.emit()

func newGoal(init=false):
	var goal = preload("res://scenes/miscellaneous/TimingTarget.tscn").instantiate()
	goal.scale.x -=  (size_penalty * points)
	if init:
		#debugPoints((size*-1)+100, size)
		goal.position = Vector2(randf_range((size*-1)+100,size), 0)
	else:
		
		if size > 0:
#			debugPoints(target.position.x+100, size)
			goal.position = Vector2(randf_range(target.position.x+100,size),0)
		elif size < 0:
			goal.position = Vector2(randf_range(target.position.x-100,size),0)
	add_child(goal)

#func debugPoints(start, end):
#	if get_node('start') != null:
#		remove_child(get_node('start'))
#		remove_child(get_node('end'))
#
#	var start_point = preload("res://scenes/miscellaneous/TimingTarget.tscn").instantiate()
#	var end_point = preload("res://scenes/miscellaneous/TimingTarget.tscn").instantiate()
#	start_point.scale.x = 0.1
#	end_point.scale.x = 0.1
#	start_point.modulate = Color(0, 1, 0)
#	end_point.modulate = Color(1, 0, 0)
#	start_point.position.x = start
#	end_point.position.x = end
#	start_point.name = 'start'
#	end_point.name = 'end'
#	start_point.z_index = 0
#	end_point.z_index = 0
#	add_child(start_point)
#	add_child(end_point)
