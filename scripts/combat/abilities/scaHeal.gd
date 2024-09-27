static func animate(caster, _target, _ability):
	await caster.doAnimation('Cast_Block')
	applyEffects(caster, _target, _ability)

static func applyEffects(_caster, target, _ability):
	CombatGlobals.calculateHealing(target, 5)
	CombatGlobals.ability_finished.emit()
