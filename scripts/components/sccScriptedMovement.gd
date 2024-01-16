extends Node
class_name ScriptedMovement

var BODY: CharacterBody2D
var TARGET_POSITIONS = []
var MOVE_SPEED = 35
var ANIMATE_DIRECTION

signal movement_finished

func _ready():
	BODY = get_parent()
	BODY.set_physics_process(false)
	BODY.set_collision_layer_value(1, false)
	BODY.set_collision_mask_value(1, false)

func _physics_process(delta):
	BODY.move_and_slide()
	
	if !TARGET_POSITIONS.is_empty():
		BODY.velocity = BODY.global_position.direction_to(TARGET_POSITIONS[0]) * MOVE_SPEED
		
		if BODY is PlayerScene and ANIMATE_DIRECTION:
			OverworldGlobals.getPlayer().direction = BODY.velocity.normalized()
	
	if !TARGET_POSITIONS.is_empty() and BODY.global_position.distance_to(TARGET_POSITIONS[0]) < 1.0:
		TARGET_POSITIONS.remove_at(0)
	elif TARGET_POSITIONS.is_empty():
		BODY.velocity = Vector2.ZERO
		BODY.set_collision_layer_value(1, true)
		BODY.set_collision_mask_value(1, true)
		movement_finished.emit()
		BODY.set_physics_process(true)
		queue_free()

func moveBody(move_sequence: String):
	move_sequence = move_sequence.replace('>', '')
	var movements = move_sequence.split(",")
	var previous_position
	for i in range(movements.size()):
		var direction
		match movements[i].substr(0,1):
			"L": direction = Vector2(-1, 0) * Vector2(int(movements[i].substr(1,2)), 0)
			"R": direction = Vector2(1, 0) * Vector2(int(movements[i].substr(1,2)), 0)
			"U": direction = Vector2(0, -1) * Vector2(0, int(movements[i].substr(1,2)))
			"D": direction = Vector2(0, 1) * Vector2(0, int(movements[i].substr(1,2)))
		
		if i == 0:
			TARGET_POSITIONS.append(BODY.global_position + direction)
			previous_position = BODY.global_position + direction
		else:
			TARGET_POSITIONS.append(previous_position + direction)
			previous_position = previous_position + direction
