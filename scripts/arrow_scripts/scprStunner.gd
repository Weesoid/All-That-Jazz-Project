static func applyEffect(body: CharacterBody2D):
	print('Stun!')
	body.get_node("NPCPatrolComponent").stunMode()
