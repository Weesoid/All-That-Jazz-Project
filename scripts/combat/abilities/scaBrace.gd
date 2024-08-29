static func animate(caster, _target, _ability):
	await caster.doAnimation()
	applyEffects(caster, _target, _ability)

static func applyEffects(caster, _target, _ability):
	CombatGlobals.addStatusEffect(caster.combatant_resource, 'Brace', true)
	CombatGlobals.ability_finished.emit()
