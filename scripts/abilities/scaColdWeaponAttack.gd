static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 10, 0.5, preload("res://resources/damage_types/Cold.tres"))
	
