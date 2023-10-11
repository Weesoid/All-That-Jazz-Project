static func equip():
	OverworldGlobals.getPlayer().walk_speed += 20.0

static func unequip():
	OverworldGlobals.getPlayer().walk_speed -= 20.0
