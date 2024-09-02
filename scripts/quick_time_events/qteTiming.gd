extends Node2D

@onready var target: Area2D = $TimingTarget
@onready var target_animator = $TimingTarget/AnimationPlayer
@onready var bar = $TimingBar

var size = 90
var target_speed = 2.5
var max_points = 1
var points = 0
var size_penalty = 0.15

func _enter_tree():
	newGoal(true)

func _physics_process(delta):
	moveTarget(delta)

func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_accept"):
		target_animator.play("Activate")
		if target.has_overlapping_areas():
			target.get_overlapping_areas()[0].queue_free()
			randomize()
			target_speed += randf_range(0.25, 0.5)
			points += 1
			size*=-1
			OverworldGlobals.playSound("res://audio/sounds/542003__rob_marion__gasp_lock-and-load.ogg", 0.0, 1.0 + (0.025 * points))
			if points == max_points:
				target.hide()
				CombatGlobals.qte_finished.emit()
			newGoal()
		else:
			OverworldGlobals.playSound("542041__rob_marion__gasp_weapon-slash_1.ogg")
			CombatGlobals.qte_finished.emit()

func moveTarget(d):
	target.global_position = lerp(target.global_position, target.global_position+Vector2(size,0), target_speed * d)
	if size > 0:
		if target.position.x >= size: CombatGlobals.qte_finished.emit()
	elif size < 0:
		if target.position.x <= size: CombatGlobals.qte_finished.emit()

func newGoal(init=false):
	var goal = preload("res://scenes/quick_time_events/targets/TimingTarget.tscn").instantiate()
	goal.scale.x -=  (size_penalty * points)
	if init:
		#debugPoints((size*-1)+90, size)
		goal.position = Vector2(randf_range((size*-1)+90,size), 0)
	else:
		
		if size > 0:
			#debugPoints(target.position.x+90, size)
			goal.position = Vector2(randf_range(target.position.x+90,size),0)
		elif size < 0:
			goal.position = Vector2(randf_range(target.position.x-90,size),0)
	call_deferred('add_child', goal)

func debugPoints(start, end):
	if has_node('start'):
		remove_child(get_node('start'))
		remove_child(get_node('end'))

	var start_point = preload("res://scenes/quick_time_events/targets/TimingTarget.tscn").instantiate()
	var end_point = preload("res://scenes/quick_time_events/targets/TimingTarget.tscn").instantiate()
	start_point.scale.x = 0.1
	end_point.scale.x = 0.1
	start_point.modulate = Color.GREEN
	end_point.modulate = Color.BLUE
	start_point.position.x = start
	end_point.position.x = end
	start_point.name = 'start'
	end_point.name = 'end'
	start_point.z_index = 0
	end_point.z_index = 0
	add_child(start_point)
	add_child(end_point)
