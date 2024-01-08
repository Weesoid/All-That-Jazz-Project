static func equip():
	print('Equipped! Wowza!')
	PlayerGlobals.sprint_speed += 300.0

static func unequip():
	print('Bruh.')
	PlayerGlobals.sprint_speed -= 300.0
