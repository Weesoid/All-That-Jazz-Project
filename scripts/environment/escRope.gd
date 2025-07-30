@tool
extends Node2D
class_name DynamicRope

@export var segment_count: int:
	set(seg_count):
		if seg_count >= 0:
			segment_count = seg_count
		if Engine.is_editor_hint() and seg_count >= 0:
			initializeRope()
@export var must_shoot: bool = false
@onready var top_pin = $PinArea
@onready var top_pin_tex = $Pin
@onready var climber_area: Area2D = $Area2D
@onready var climber_shape = $Area2D/CollisionShape2D
var rope_length = 0
var segments: Array

func _ready():
	if !must_shoot:
		initializeRope()

func moveEnterArea(pos: Vector2):
	top_pin.position = pos

func isPlayerOnEnterArea():
	return top_pin.get_overlapping_bodies().has(OverworldGlobals.getPlayer())

func createSegment():
	var segment = load("res://scenes/environment/RopeSegment.tscn").instantiate()
	if segments.size() == 0:
		segment.position = Vector2(0,24)
	else:
		segment.position = Vector2(0,(48*segments.size())+24)
	if !Engine.is_editor_hint():
		rope_length += 48
	segments.append(segment)
	add_child(segment)

func createPinJoint(segment_a, segment_b):
	var pin_joint: PinJoint2D = PinJoint2D.new()
	if segments.size() == 1:
		pin_joint.position = Vector2(0,0)
	else:
		pin_joint.position = Vector2(0,48*segments.size()-48)
	pin_joint.node_a = segment_a
	pin_joint.node_b = segment_b
	add_child(pin_joint)

func resizeClimbArea():
	climber_area.position = Vector2(0, rope_length/2)
	climber_shape.shape.height = float(rope_length)

func initializeRope():
	if segments.size() > 0:
		for segment in segments: 
			segment.queue_free()
		for child in get_children():
			if child is PinJoint2D: 
				child.queue_free()
		climber_area.position = Vector2.ZERO
		climber_shape.shape.height = 30.0
		segments.clear()
	
	while segments.size() != segment_count+1:
		createSegment()
		if segments.size() == 1 and !Engine.is_editor_hint():
			createPinJoint(top_pin_tex.get_path(), segments[0].get_path())
		elif segments.size() >= 2 and segments.size() and !Engine.is_editor_hint():
			createPinJoint(segments[segments.size()-2].get_path(), segments[segments.size()-1].get_path())
		if must_shoot and !Engine.is_editor_hint():
			await get_tree().create_timer(0.08).timeout
	
	if must_shoot and !Engine.is_editor_hint():
		must_shoot = false
	if !Engine.is_editor_hint():
		resizeClimbArea()

func _on_pin_area_area_entered(area):
	print(area)
	if area is Projectile and must_shoot:
		initializeRope()
