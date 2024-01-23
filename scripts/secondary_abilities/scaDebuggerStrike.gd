static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(caster: ResCombatant, targets, animation_scene):
	if targets is Array:
		for target in targets:
			CombatGlobals.playAbilityAnimation(target, animation_scene)
			CombatGlobals.calculateDamage(caster, target, 'brawn', 'grit', 100, 100, preload("res://resources/damage_types/Neutral.tres"),false)
	else:
		CombatGlobals.playAbilityAnimation(targets, animation_scene)
		CombatGlobals.calculateDamage(caster, targets, 'brawn', 'grit', 100, 100, preload("res://resources/damage_types/Neutral.tres"),false)
