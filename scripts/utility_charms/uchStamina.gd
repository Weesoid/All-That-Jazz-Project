static func equip():
	OverworldGlobals.getPlayer().stamina_gain += 5.0

static func unequip():
	OverworldGlobals.getPlayer().max_bow_draw -= 5.0
