static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Cast')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')

static func applyEffects(caster: ResCombatant, target: ResCombatant, animation_scene):
	# Visual Feedback
	CombatGlobals.playAbilityAnimation(target, animation_scene)
	CombatGlobals.calculateHealing(caster, 10.0)
	

static func applyOverworldEffects():
	for combatant in PlayerGlobals.TEAM:
		if combatant.active:
			CombatGlobals.calculateHealing(combatant, 50)
