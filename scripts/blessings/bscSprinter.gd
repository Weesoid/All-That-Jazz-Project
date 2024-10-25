static func apply(equip: bool):
	var amount = 0.5
	if equip:
		PlayerGlobals.overworld_stats['stamina'] += amount
	else:
		PlayerGlobals.overworld_stats['stamina'] -= amount
