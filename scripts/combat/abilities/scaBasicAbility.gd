# Cast animations, gap closing, etc.
static func animate(caster: CombatantScene, target, ability:ResAbility):
	for effect in ability.BASIC_EFFECTS:
		ability.current_effect = effect
		if effect.animate_on == 1:
			await playAnimation(ability, caster)
		if effect.sound_effect != '': 
			OverworldGlobals.playSound(effect.sound_effect)
	
		if effect is ResDamageEffect:
			await doAttackAnimations(caster, target, ability, effect)
		elif effect is ResCustomDamageEffect:
			await applyEffects(caster, target, ability)
		elif effect is ResApplyStatusEffect:
			await caster.doAnimation(effect.cast_animation)
			await applyEffects(caster, target, ability)
		elif effect is ResMoveEffect:
			if effect.target == effect.Target.CASTER:
				target = caster
			else:
				target = target
			if effect.direction == effect.Direction.FORWARD:
				await CombatGlobals.getCombatScene().changeCombatantPosition(target.combatant_resource, 1)
			elif effect.direction == effect.Direction.BACK:
				await CombatGlobals.getCombatScene().changeCombatantPosition(target.combatant_resource, -1)
		elif effect is ResHealEffect:
			await caster.doAnimation(effect.cast_animation)
			await applyEffects(caster, target, ability)
		elif effect is ResCommandAbilityEffect:
			CombatGlobals.execute_ability.emit(target, effect.ability)
			await CombatGlobals.get_tree().create_timer(0.25).timeout
	
	CombatGlobals.ability_finished.emit()

# Determine if target(s) is single or multi
static func applyEffects(caster: CombatantScene, target, ability: ResAbility):
	if target is Array:
		for t in target: 
			applyToTarget(caster, t, ability)
			if ability.current_effect.animate_on == 0: 
				await playAnimation(ability, t)
	else:
		applyToTarget(caster, target, ability)
		if ability.current_effect.animate_on == 0: 
			await playAnimation(ability, target)

static func playAnimation(ability: ResAbility, target):
	if target is CombatantScene:
		target = target.combatant_resource
	
	if ability.current_effect.animation != null and ability.current_effect.animation_time >= 0.0:
		await CombatGlobals.playAbilityAnimation(target, ability.current_effect.animation, ability.current_effect.animation_time)
	elif ability.current_effect.animation != null:
		CombatGlobals.playAbilityAnimation(target, ability.current_effect.animation, ability.current_effect.animation_time)

# Combat values calculations (damage, healing, etc.)
static func applyToTarget(caster, target, ability: ResAbility):
	if ability.current_effect is ResDamageEffect:
		if CombatGlobals.calculateDamage(caster, target, ability.current_effect.damage, ability.current_effect.can_miss, ability.current_effect.can_crit) and ability.current_effect.apply_status != null:
			CombatGlobals.addStatusEffect(target.combatant_resource, ability.current_effect.apply_status, true)
	
	elif ability.current_effect is ResCustomDamageEffect:
		if !ability.current_effect.use_caster:
			caster = null
		else:
			caster = caster.combatant_resource
		if CombatGlobals.calculateRawDamage(target, ability.current_effect.damage, caster, ability.current_effect.can_crit, ability.current_effect.crit_chance, ability.current_effect.can_miss, ability.current_effect.variation, ability.current_effect.message, ability.current_effect.trigger_on_hits) and ability.current_effect.apply_status != null:
			CombatGlobals.addStatusEffect(target.combatant_resource, ability.current_effect.apply_status, true)
	
	elif ability.current_effect is ResApplyStatusEffect:
		if ability.current_effect.target == ability.current_effect.Target.TARGET:
			target = target.combatant_resource
		elif ability.current_effect.target == ability.current_effect.Target.CASTER:
			target = caster.combatant_resource
		CombatGlobals.addStatusEffect(target, ability.current_effect.status_effect, true)
	
	elif ability.current_effect is ResHealEffect:
		CombatGlobals.calculateHealing(target, ability.current_effect.heal)

# Attack animations (Ranged, melee)
static func doAttackAnimations(caster: CombatantScene, target, ability:ResAbility, damage_effect: ResDamageEffect):
	if damage_effect.damage_type == damage_effect.DamageType.MELEE:
		await caster.moveTo(target)
		await caster.doAnimation('Cast_Melee', ability.ABILITY_SCRIPT)
		if damage_effect.return_pos: await caster.moveTo(caster.get_parent())
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED:
		await caster.doAnimation('Cast_Ranged', ability.ABILITY_SCRIPT, {'target'=target,'frame_time'=0.7})
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED_PIERCING:
		await caster.doAnimation('Cast_Ranged', ability.ABILITY_SCRIPT, {'target'=null,'frame_time'=0.7})
