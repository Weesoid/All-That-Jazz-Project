static func equip():
	PlayerGlobals.bow_max_draw -= 2.0

static func unequip():
	PlayerGlobals.bow_max_draw += 2.0
	print('blegh!')
