static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	await caster.moveTo(target)
	await skillCheck(target, caster, 'Holding',ability,4)
	await caster.moveTo(caster.get_parent())
	CombatGlobals.ability_finished.emit()

static func skillCheck(target: CombatantScene , caster: CombatantScene, check: String, ability: ResAbility, count:int=1):
	print(caster.combatant_resource, ' <- ')
	var qte = await CombatGlobals.spawnQuickTimeEvent(target, check, count)
	var points = qte.points
	qte.queue_free()
	await CombatGlobals.playAbilityAnimation(caster.combatant_resource, ability.ANIMATION)
	match points:
		1:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Singed')
		2:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Jolted')
		3:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Poison')
		4:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Chilled')

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5)
