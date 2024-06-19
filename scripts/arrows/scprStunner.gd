static func applyEffect(body: CharacterBody2D):
	# Add status effects here
	if body.get_node("NPCPatrolComponent").STATE != 3:
		var combat_interact = preload("res://scenes/components/CombatInteract.tscn").instantiate()
		combat_interact.patroller_name = body.get_node("NPCPatrolComponent").NAME
		body.call_deferred('add_child', combat_interact)
	
	body.get_node("NPCPatrolComponent").updateMode(3)
