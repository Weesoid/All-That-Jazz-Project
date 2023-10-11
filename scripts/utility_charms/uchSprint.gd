static func equip():
	print('Equipped! Wowza!')
	OverworldGlobals.getPlayer().sprint_speed += 300.0

static func unequip():
	print('Bruh.')
	OverworldGlobals.getPlayer().sprint_speed -= 300.0
