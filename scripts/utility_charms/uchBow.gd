static func equip():
	OverworldGlobals.getPlayer().bow_max_draw -= 2.0

static func unequip():
	OverworldGlobals.getPlayer().bow_max_draw += 2.0
