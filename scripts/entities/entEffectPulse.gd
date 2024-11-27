extends Area2D
class_name EffectPulse

@export var hit_script: GDScript

@onready var shape: CollisionShape2D = $CollisionShape2D
var color: Color = Color.WHITE
var radius: float

func _ready():
	shape.shape.radius = radius

func _process(_delta):
	if has_overlapping_bodies():
		applyPulseEffect()

func applyPulseEffect():
	for body in get_overlapping_bodies():
		hit_script.applyEffect(body)
	
	showPulse()
	queue_free()

func showPulse():
	var pulse_anim = preload("res://scenes/entities_disposable/Pulse.tscn").instantiate()
	pulse_anim.global_position = global_position
	OverworldGlobals.getCurrentMap().add_child(pulse_anim)
	pulse_anim.showAnimation(radius, 0.4,color)
