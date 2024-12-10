static func applyEffect(body: CharacterBody2D):
	await OverworldGlobals.getCurrentMap().get_node('PlayerArrow').tree_exited
	body.queue_free()
