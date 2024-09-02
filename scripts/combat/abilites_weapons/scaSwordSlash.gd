static func animate(caster: CombatantScene, target: CombatantScene, _ability: ResAbility):
	await caster.moveTo(target)
	await skillCheck(target, caster, 'Holding')
	await skillCheck(target, caster, 'Inputting')
	await skillCheck(target, caster, 'Mashing')
	await skillCheck(target, caster, 'Timing')
	await caster.moveTo(caster.get_parent())
	CombatGlobals.ability_finished.emit()

static func skillCheck(target: CombatantScene , caster: CombatantScene, check: String):
	var qte = await CombatGlobals.spawnQuickTimeEvent(target, check)
	if qte.points > 0:
		qte.queue_free()
		CombatGlobals.addStatusEffect(caster.combatant_resource, 'BrawnUp', true)
		await caster.doAnimation('Cast_Weapon')
	else:
		qte.queue_free()
		return

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5.0)
