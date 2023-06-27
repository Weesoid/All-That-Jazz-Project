extends Area2D

var SPEED = 1500.0
var SHOOTER: CharacterBody2D

func _physics_process(delta):
	
	global_position += Vector2(cos(rotation), sin(rotation)) * SPEED * delta
	

func _on_body_entered(body):
	if body.has_node('HurtBoxComponent'):
		print('Caught body: ', body)
		body.get_node('HurtBoxComponent').destroy()
	if body != SHOOTER:
		queue_free()
	
