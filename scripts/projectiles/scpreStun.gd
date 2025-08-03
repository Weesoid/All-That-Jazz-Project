static func applyEffect(body: CharacterBody2D):
	#OverworldGlobals.damageParty(5)
	var combat_interact = load("res://scenes/components/CombatInteract.tscn").instantiate()
	body.call_deferred('add_child', combat_interact)
	var stun_stars = load("res://scenes/miscellaneous/StunStars.tscn").instantiate()
	stun_stars.global_position = Vector2(-24,24)
	combat_interact.tree_exited.connect(func(): stun_stars.queue_free())
	body.add_child(stun_stars)
