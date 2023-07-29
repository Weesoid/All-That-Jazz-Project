static func animateCast(caster: ResCombatant):
	caster.getAnimator().play('Attack')
	await caster.getAnimator().animation_finished
	caster.getAnimator().play('Idle')
	
static func applyEffects(_caster: ResCombatant, target: ResCombatant, animation_scene):
	var status_effect = CombatGlobals.loadStatusEffect('BrawnUp')
	
	CombatGlobals.playSingleTargetAnimation(target, animation_scene)
	CombatGlobals.addStatusEffect(target, status_effect)
	
	await animation_scene.get_node('AnimationPlayer').animation_finished
	CombatGlobals.emit_ability_executed()
	
