static func animate(caster, _target, _ability):
	applyEffects(caster, _target, _ability)
	await caster.doAnimation('Cast_Melee')
	CombatGlobals.ability_finished.emit()

static func applyEffects(caster, _target, _ability):
	CombatGlobals.addStatusEffect(caster.combatant_resource, 'Riposte')
