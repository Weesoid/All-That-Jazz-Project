static func applyEffect(body: CharacterBody2D):
	body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getExperience()
	body.get_node("NPCPatrolComponent").destroy()
	var lootbag = preload("res://scenes/entities_disposable/LootBag.tscn").instantiate()
	lootbag.get_node("Interaction").loot = body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getRawDrops()
	lootbag.position = body.position
	OverworldGlobals.getCurrentMap().call_deferred('add_child', lootbag)
