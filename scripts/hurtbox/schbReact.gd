static func applyEffect(body: CharacterBody2D, scene: Node2D):
	scene.get_node("MrMovey").get_node("InteractComponent").interact()
	
	body.get_node("Animator").play('KO')
	await body.get_node("Animator").animation_finished
	body.queue_free()
