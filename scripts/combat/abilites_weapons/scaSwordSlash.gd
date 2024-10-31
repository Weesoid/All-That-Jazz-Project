static func animate(caster: CombatantScene, target: CombatantScene, _ability: ResAbility):
#	await caster.moveTo(target)
	#await skillCheck(target, caster, 'Holding')
	#await skillCheck(target, caster, 'Inputting')
	#await skillCheck(target, caster, 'Mashing')
#	await skillCheck(target, caster, 'Holding', 4)
#	await caster.moveTo(caster.get_parent())
	await CombatGlobals.getCombatScene().changeCombatantPosition(caster.combatant_resource, 0, 120)
	CombatGlobals.ability_finished.emit()

static func skillCheck(target: CombatantScene , caster: CombatantScene, check: String, count:int=1):
	var qte = await CombatGlobals.spawnQuickTimeEvent(target, check, count)
	var points = qte.points
	qte.queue_free()
	await caster.doAnimation('Cast_Weapon')
	match points:
		1:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Singed', true)
		2:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Jolted', true)
		3:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Poison', true)
		4:
			CombatGlobals.addStatusEffect(target.combatant_resource, 'Chilled', true)

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5)
