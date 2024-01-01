static func applyEffect(body: CharacterBody2D):
	OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]Morale[/color] increased!')
	body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getExperience()
	body.get_node("NPCPatrolComponent").destroy()
	var lootbag = preload("res://scenes/entities/LootBag.tscn").instantiate()
	lootbag.get_node("Interaction").loot = body.get_node("NPCPatrolComponent").COMBAT_SQUAD.getRawDrops()
	lootbag.position = body.position
	OverworldGlobals.getCurrentMap().call_deferred('add_child', lootbag)
