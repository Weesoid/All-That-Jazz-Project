static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
#	if caster.combatant_resource is ResPlayerCombatant:
#		await caster.moveTo(target)
#		await skillCheck(target, caster, ability)
#		await caster.moveTo(caster.get_parent())
#		CombatGlobals.ability_finished.emit()
#	else:
#		await caster.moveTo(target)
#		await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
#		await caster.moveTo(caster.get_parent())
#		CombatGlobals.ability_finished.emit()
	await caster.moveTo(target)
	await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
	await caster.moveTo(caster.get_parent())
	CombatGlobals.ability_finished.emit()

static func skillCheck(target: CombatantScene , caster: CombatantScene, ability: ResAbility=null):
	if caster.combatant_resource is ResPlayerCombatant:
		for i in range(3):
			var qte = preload("res://scenes/quick_time_events/Timing.tscn").instantiate()
			qte.global_position = target.global_position
			CombatGlobals.getCombatScene().add_child(qte)
			await CombatGlobals.qte_finished
			qte.queue_free()
			await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)

static func applyEffects(target: CombatantScene , caster: CombatantScene, ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 3.0)
