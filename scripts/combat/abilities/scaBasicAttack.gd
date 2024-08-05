static func applyEffects(caster: ResCombatant, target, ability):
	await caster.moveTo(target)
	#await caster.doAttack()
	ability.ANIMATION.get_node('AnimationPlayer').play('Show')
	
	await caster.moveTo(caster.get_parent())
