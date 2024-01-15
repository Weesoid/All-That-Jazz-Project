extends Node
class_name ScriptedMovement

var BODY: CharacterBody2D
var BASE_MOVE_SPEED = 35
var TARGET_LOCATION
var MOVE_SPEED
var ANIMATE_DIRECTION
var MOVE_COUNT = 0

signal target_reached
signal movement_finished

func _ready():
	BODY = get_parent()
	MOVE_SPEED = BASE_MOVE_SPEED

func _physics_process(delta):
	BODY.move_and_slide()
	BODY.set_collision_layer_value(1, false)
	BODY.set_collision_mask_value(1, false)
	
	if TARGET_LOCATION != null:
		BODY.velocity = BODY.global_position.direction_to(TARGET_LOCATION) * MOVE_SPEED
		if BODY is PlayerScene and ANIMATE_DIRECTION:
			OverworldGlobals.getPlayer().direction = BODY.velocity.normalized()
	
	if BODY.global_position.distance_to(TARGET_LOCATION) < 1.0 and MOVE_COUNT == 0:
		TARGET_LOCATION = null
		BODY.velocity = Vector2.ZERO
		target_reached.emit()
		BODY.set_collision_layer_value(1, true)
		BODY.set_collision_mask_value(1, true)
		movement_finished.emit()
		queue_free()

func setBodyCollision(set: bool):
	BODY.set_collision_layer_value(1, set)
	BODY.set_collision_mask_value(1, set)

func moveBody(move_sequence: String):
	move_sequence = move_sequence.replace('>', '')
	var movements = move_sequence.split(",")
	MOVE_COUNT = movements.size()
	for movement in movements:
		var direction
		# TO DO Add maintain direction with L10m? where m is maintain direction?
		match movement.substr(0,1):
			"L": direction = Vector2(-1, 0) * Vector2(int(movement.substr(1,2)), 0)
			"R": direction = Vector2(1, 0) * Vector2(int(movement.substr(1,2)), 0)
			"U": direction = Vector2(0, -1) * Vector2(0, int(movement.substr(1,2)))
			"D": direction = Vector2(0, 1) * Vector2(0, int(movement.substr(1,2)))
		
		TARGET_LOCATION = BODY.global_position + direction
		MOVE_COUNT -= 1
	
	movement_finished.emit()
