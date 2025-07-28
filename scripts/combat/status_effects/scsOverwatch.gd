static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(
		caster, 
		target, 
		2+caster.combatant_resource.stat_values['health']*0.01,
		true,
		false,
		'',
		'',
		{'status_effect': 'Knockback'}
		)
	#CombatGlobals.addStatusEffect(target.combatant_resource, 'Knockback', true)

static func animate(caster, target):
	caster.combatant_scene.z_index = 99 
	applyEffects(caster.combatant_scene, target)
	await caster.combatant_scene.doAnimation('Cast_Melee')
	caster.combatant_scene.z_index = 0

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
