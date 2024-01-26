static func selectAbility(abilities: Array[ResAbility]):
	abilities = abilities.filter(
		func getEnabled(ability):
			return ability.ENABLED
	)
	randomize()
	return abilities.pick_random()
	
static func selectTarget(combatants: Array[ResCombatant]):
	# DO NOT ALLOW THIS TO RUN WHEN BATTLE IS DONE!! (e.g. no more targets)
	randomize()
	return combatants.pick_random()
	
