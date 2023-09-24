extends Area2D

var SPEED = 1500.0
var SHOOTER: CharacterBody2D

func _physics_process(delta):
	global_position += Vector2(cos(rotation), sin(rotation)) * SPEED * delta

func _process(_delta):
	if global_position.distance_to(OverworldGlobals.getPlayer().global_position)>2500.0:
		queue_free()

func _on_body_entered(body):
	if body.has_node('NPCPatrolComponent'):
		PlayerGlobals.EQUIPPED_ARROW.applyOverworldEffect(body)
	
	elif body.has_node('HurtBoxComponent'):
		body.get_node('HurtBoxComponent').applyEffect()
	
	if body != SHOOTER:
		queue_free()
	
