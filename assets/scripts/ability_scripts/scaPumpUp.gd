static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	var status_effect = CombatGlobals.loadStatusEffect('BrawnUp')
	
	if status_effect.NAME not in target.getStatusEffectNames():
		CombatGlobals.addStatusEffect(target, status_effect)
	else:
		CombatGlobals.rankUpStatusEffect(target, status_effect)
		
	target.getAnimator().play('Attack')
	await target.getAnimator().animation_finished
	target.getAnimator().play('Idle')
	
	CombatGlobals.emit_ability_executed()
	
