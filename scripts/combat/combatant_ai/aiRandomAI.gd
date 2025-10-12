static func selectAbility(abilities: Array[ResAbility], caster: ResCombatant):
	abilities = abilities.filter(
		func getEnabled(ability: ResAbility):
			return ability.enabled and ability.canUse(caster, ability.getValidTargets(CombatGlobals.getCombatScene().sortCombatantsByPosition(), caster is ResPlayerCombatant))
	)
	print(abilities)
	if !abilities.is_empty():
		randomize()
		return abilities.pick_random()
	else:
		return null

static func selectTarget(combatants: Array[ResCombatant]):
	if combatants.is_empty(): return
	randomize()
	return combatants.pick_random()
