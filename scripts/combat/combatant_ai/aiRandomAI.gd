static func selectAbility(abilities: Array[ResAbility], caster: ResCombatant):
	abilities = abilities.filter(
		func getEnabled(ability: ResAbility):
			for effect in ability.BASIC_EFFECTS:
				if effect is ResApplyStatusEffect and caster.hasStatusEffect(effect.status_effect.NAME):
					return false
			return ability.ENABLED and ability.canUse(caster)
	)
	randomize()
	return abilities.pick_random()

static func selectTarget(combatants: Array[ResCombatant]):
	if combatants.is_empty(): return
	randomize()
	return combatants.pick_random()
