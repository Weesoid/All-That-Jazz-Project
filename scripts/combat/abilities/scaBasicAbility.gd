# Cast animations, gap closing, etc.
static func animate(caster: CombatantScene, target, ability:ResAbility):
	for effect in ability.basic_effects:
		ability.current_effect = effect
		var check_target = target[0] if target is Array else target.combatant_resource
		if !ability.current_effect.conditionPassed(check_target): 
			continue
		
		if effect.animate_on == 1:
			await playAnimation(ability, caster)
		if effect.sound_effect != null: 
			OverworldGlobals.playSound(effect.resource_path)
		
		if effect is ResAttackEffect:
			await doAttackAnimations(caster, target, ability, effect)
		
		elif effect is ResCustomDamageEffect:
			if effect.cast_animation != '': await caster.doAnimation(effect.cast_animation)
			await applyAbilityEffects(caster, target, ability)
		
		elif effect is ResApplyStatusEffect:
			if caster != null:
				await caster.doAnimation(effect.cast_animation)
			await applyAbilityEffects(caster, target, ability)
		
		elif effect is ResMoveEffect:
			if effect.target == effect.Target.CASTER:
				target = caster
			else:
				target = target
			if effect.direction == effect.Direction.FORWARD:
				await CombatGlobals.getCombatScene().moveCombatant(target.combatant_resource, -1, effect.move_count)
			elif effect.direction == effect.Direction.BACK:
				await CombatGlobals.getCombatScene().moveCombatant(target.combatant_resource, 1, effect.move_count)
		
		elif effect is ResHealEffect:
			await caster.doAnimation(effect.cast_animation)
			if ability.current_effect.base_heal > 0: 
				CombatGlobals.calculateHealing(target, ability.current_effect.base_heal, ability.current_effect.use_multiplier)
			if ability.current_effect.percent_heal > 0.0: 
				CombatGlobals.calculatePercentHealing(target.combatant_resource, ability.current_effect.percent_heal, ability.current_effect.use_multiplier)
		
		elif effect is ResHealResolveEffect:
			CombatGlobals.healResolve(target.combatant_resource, effect.amount)
		
		elif effect is ResCommandAbilityEffect:
			CombatGlobals.execute_ability.emit(target, effect.ability)
			await CombatGlobals.get_tree().create_timer(0.5).timeout
		
		elif effect is ResAddTPEffect:
			CombatGlobals.addTension(effect.add_amount, caster.combatant_resource, target.combatant_resource)
			await applyAbilityEffects(caster, target, ability)
		
		elif ability.current_effect is ResChangeIdleEffect and target.temporary_idle != ability.current_effect.idle_name:
			target.temporary_idle = ability.current_effect.idle_name
			target.playIdle()
		
		elif ability.current_effect is ResStatModifierEffect:
			target.combatant_resource.addTemporaryModifer(
				ability.name, 
				ability.current_effect.duration,
				ability.current_effect.getModifications(),
				ability.current_effect.stacks,
				ability.current_effect.duration_type == ResStatModifierEffect.DurationType.BATTLE,
				ability.current_effect.resistable
				)
		
		elif ability.current_effect is ResCleanseEffect:
			CombatGlobals.removeStatusEffect(target.combatant_resource, ability.current_effect.cleanse_status.name)
		
		elif ability.current_effect is ResDotEffect:
			var dot_data = ability.current_effect.getDot()
			CombatGlobals.addStatusEffect(target.combatant_resource, dot_data[0], false, dot_data[1])
		
	await CombatGlobals.getCombatScene().get_tree().process_frame
	CombatGlobals.ability_finished.emit()

# Determine if target(s) are single or multi then apply ability effects
static func applyAbilityEffects(caster: CombatantScene, target, ability: ResAbility):
	if ability.current_effect == null:
		ability.current_effect = ability.basic_effects[0] # Mainly to fix follow up ability, as the projectile only runs THIS function and nothin else. Bugs later? idc.
	
#	if target is Array and ability.current_effect.is_combo_effect and ability.current_effect.effect_only_combo_targets:
#		target = target.filter(func(combatant): return combatant.hasStatusEffect('Combo'))
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

# Combat values calculations (damage, healing, etc.) APPLIES ON ATTACK HITBOX
static func applyToTarget(caster, target, ability: ResAbility):
	if ability.current_effect is ResAttackEffect:
		CombatGlobals.calculateDamage(
				caster, 
				target, 
				ability.current_effect.damage_modifier, 
				ability.current_effect.can_crit, 
				'', 
				ability.current_effect.indicator_bb,
				ability.current_effect.getAttackBonuses(target.combatant_resource)
				)
#		if ability.current_effect.plant_self_on_combo and target.combatant_resource.hasStatusEffect('Combo'):
#			ability.current_effect.do_not_return_pos = true
		
#		if (target.combatant_resource.hasStatusEffect('Combo') and ability.current_effect.is_combo_effect): #and !ability.current_effect.plant_self_on_combo:
#			#CombatGlobals.manual_call_indicator_bb.emit(target.combatant_resource, 'COMBO!!', 'Show', '[img]res://images/sprites/icon_combo.png[/img] [color=turquoise]')
#			target.combatant_resource.getStatusEffect('Combo').removeStatusEffect()
	
	elif ability.current_effect is ResCustomDamageEffect:
		if !ability.current_effect.use_caster:
			caster = null
		else:
			caster = caster.combatant_resource
		if target is CombatantScene:
			target = target.combatant_resource
		CombatGlobals.calculateRawDamage(
			target, 
			ability.current_effect.damage,
			caster, 
			ability.current_effect.can_crit, 
			ability.current_effect.crit_chance, 
			ability.current_effect.variation, 
			ability.current_effect.trigger_on_hits, 
			'', 
			ability.current_effect.indicator_bb,
			ability.current_effect.bonus_stats
			)
	
	elif ability.current_effect is ResApplyStatusEffect:
		if ability.current_effect.target == ability.current_effect.Target.TARGET:
			if target is CombatantScene:
				target = target.combatant_resource
		elif ability.current_effect.target == ability.current_effect.Target.CASTER:
			if target is CombatantScene:
				target = caster.combatant_resource
			else:
				target = caster
		CombatGlobals.addStatusEffect(target, ability.current_effect.status_effect)
	
#	elif ability.current_effect is ResHealEffect:
#		if ability.current_effect.base_heal > 0: 
#			CombatGlobals.calculateHealing(target, ability.current_effect.base_heal, ability.current_effect.use_multiplier)
#		if ability.current_effect.percent_heal > 0.0: 
#			CombatGlobals.calculatePercentHealing(target.combatant_resource, ability.current_effect.percent_heal, ability.current_effect.use_multiplier)
		
# Attack animations (Ranged, melee)
static func doAttackAnimations(caster: CombatantScene, target, ability:ResAbility, damage_effect: ResAttackEffect):
	var animation_data = {}
	var animation = ''
	if target is Array[ResCombatant]:
		animation_data['target_count'] = target.size()
	
	if damage_effect.cast_animation['animation'] != '':
		if damage_effect.cast_animation['go_to_target']:
			await caster.moveTo(target)
		await caster.doAnimation(damage_effect.cast_animation['animation'], ability.ability_script, animation_data)
		if damage_effect.cast_animation['go_to_target']:
			await returnToPosition(damage_effect, caster)

	elif damage_effect.damage_type == damage_effect.DamageType.MELEE:
		await caster.moveTo(target)
		await caster.doAnimation(pickAnimation(caster, 'Melee'), ability.ability_script, animation_data) # SPEED UP {'anim_speed':1.5}
		await returnToPosition(damage_effect, caster)
	
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED:
		#animation_data['projectile_texture'] = ability.current_effect.projectile_texture
		await caster.doAnimation(pickAnimation(caster, 'Ranged'), ability.ability_script, 
			{
				'target'=target,
				'frame_time'=0.4,
				'ability'=ability, 
				'projectile_texture'=ability.current_effect.projectile_texture
			}
		)
	
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED_PIERCING:
		#animation_data['projectile_texture'] = ability.current_effect.projectile_texture
		await caster.doAnimation(pickAnimation(caster, 'Ranged'), ability.ability_script, 
			{
				'target'=null,
				'frame_time'=0.4,
				'ability'=ability, 
				'projectile_texture'=ability.current_effect.projectile_texture
			}
		)

static func pickAnimation(caster:CombatantScene, type:String):
	randomize()
	var animations:Array[String]
	animations.assign(caster.animator.get_animation_list())
	animations=animations.filter(func(anim): return anim.contains('Cast_%s_Variation' % type.capitalize()))
	animations.append('Cast_%s' % type.capitalize())
	#print('valid anims: ',animations)
	return animations.pick_random()

static func returnToPosition(damage_effect: ResAttackEffect, caster: CombatantScene):
	if !damage_effect.return_pos: 
		return
	await caster.moveTo(CombatGlobals.getCombatScene().getRankPosition(caster.combatant_resource))
#	if damage_effect.do_not_return_pos:
#		damage_effect.do_not_return_pos = false

#static func canDoCombo(effect: ResAbilityEffect, target)-> bool:
#	if target is CombatantScene:
#		return effect.is_combo_effect and target.combatant_resource.hasStatusEffect('Combo')
#	elif target is  Array:
#		target = target.filter(func(combatant): return combatant.hasStatusEffect('Combo'))
#		return effect.is_combo_effect and target.size() > 0
#
#	return false

# Returns true if target meets combo requirements
#static func checkDamageCombo(target: ResCombatant, effect, check_property: String='', allow_no_combo:bool=true)-> bool:
#	return (effect.has_combo_effects and effect.canCombo(target, check_property)) or (!effect.has_combo_effects and allow_no_combo)
