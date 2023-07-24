static func selectAbility(abilities: Array[ResAbility]):
	abilities.filter(
		func getEnabledAbilities(ability):
			return ability.ENABLED
	)
	randomize()
	return abilities.pick_random()
	
static func selectTarget(combatants: Array[ResCombatant]):
	randomize()
	return combatants.pick_random()
	
