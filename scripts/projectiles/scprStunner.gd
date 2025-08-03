static func applyEffect(body: CharacterBody2D):
	if body is GenericPatroller and body.state != 2:
		var combat_interact = load("res://scenes/components/CombatInteract.tscn").instantiate()
		combat_interact.patroller_name = str(body.name)
		body.call_deferred('add_child', combat_interact)
		body.updateState(GenericPatroller.State.STUNNED)
