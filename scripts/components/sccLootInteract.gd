extends Area2D

var loot

func interact():
	for item in loot:
		InventoryGlobals.addItemResource(item, loot[item])
	OverworldGlobals.show_player_interaction = true
	get_parent().queue_free()
	queue_free()
