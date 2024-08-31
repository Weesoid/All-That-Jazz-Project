static func animate(caster: CombatantScene, target: CombatantScene, _ability: ResAbility):
	await caster.moveTo(target)
	await skillCheck(target, caster)
	await caster.moveTo(caster.get_parent())
	CombatGlobals.ability_finished.emit()

static func skillCheck(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	if caster.combatant_resource is ResPlayerCombatant:
		for i in range(3):
			var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
			qte.global_position = target.global_position
			CombatGlobals.getCombatScene().add_child(qte)
			await CombatGlobals.qte_finished
			if qte.points > 0:
				qte.queue_free()
				CombatGlobals.addStatusEffect(caster.combatant_resource, 'BrawnUp', true)
				await caster.doAnimation('Cast_Weapon')
			else:
				qte.queue_free()
				return

static func applyEffects(target: CombatantScene , caster: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 5.0)
