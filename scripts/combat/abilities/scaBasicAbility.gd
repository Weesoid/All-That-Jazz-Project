# Cast animations, gap closing, etc.
static func animate(caster: CombatantScene, target, ability:ResAbility):
	for effect in ability.basic_effects:
		ability.current_effect = effect
		#print(ability.current_effect.checkConditions(target.combatant_resource, caster.combatant_resource))
		if (target is CombatantScene and !ability.current_effect.checkConditions(target.combatant_resource, caster.combatant_resource)) or (effect.is_combo_effect and !canDoCombo(effect, target)):
			continue
		elif ability.getTargetType() == 1 and canDoCombo(effect, target) and !effect is ResDamageEffect:
			target.combatant_resource.getStatusEffect('Combo').removeStatusEffect()
		
		if effect.animate_on == 1:
			await playAnimation(ability, caster)
		if effect.sound_effect != '': 
			OverworldGlobals.playSound(effect.sound_effect)
		
		if effect is ResDamageEffect:
			await doAttackAnimations(caster, target, ability, effect)
		elif effect is ResCustomDamageEffect:
			if effect.cast_animation != '': await caster.doAnimation(effect.cast_animation)
			await applyEffects(caster, target, ability)
		elif effect is ResApplyStatusEffect:
			if caster != null:
				await caster.doAnimation(effect.cast_animation)
			await applyEffects(caster, target, ability)
		elif effect is ResMoveEffect:
			if effect.target == effect.Target.CASTER:
				target = caster
			else:
				target = target
			if effect.direction == effect.Direction.FORWARD:
				await CombatGlobals.getCombatScene().changeCombatantPosition(target.combatant_resource, 1, true, effect.move_count)
			elif effect.direction == effect.Direction.BACK:
				await CombatGlobals.getCombatScene().changeCombatantPosition(target.combatant_resource, -1, true, effect.move_count)
		elif effect is ResHealEffect:
			await caster.doAnimation(effect.cast_animation)
			await applyEffects(caster, target, ability)
		elif effect is ResCommandAbilityEffect:
			CombatGlobals.execute_ability.emit(target, effect.ability)
			await CombatGlobals.get_tree().create_timer(0.5).timeout
		elif effect is ResOnslaughtEffect:
			if effect.target == effect.Target.MULTI:
				target.get_node('CombatBars').hide()
				CombatGlobals.getCombatScene().team_hp_bar.show()
			await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, true)
			CombatGlobals.getCombatScene().fadeCombatant(caster, true)
			if effect.projectile_frame != null:
				caster.setProjectileTarget(target, effect.projectile_frame, ability, 'Onslaught')
			await caster.doAnimation(effect.animation_name, ability.ability_script)
			#await CombatGlobals.getCombatScene().get_tree().process_frame # This might be stupid.
			await CombatGlobals.getCombatScene().setOnslaught(target.combatant_resource, false)
			CombatGlobals.getCombatScene().team_hp_bar.hide()
			target.get_node('CombatBars').show()
		elif effect is ResAddTPEffect:
			CombatGlobals.addTension(effect.add_amount)
			await applyEffects(caster, target, ability)
	
	#if caster == CombatGlobals.getCombatScene().active_combatant:
	await CombatGlobals.getCombatScene().get_tree().process_frame
	CombatGlobals.ability_finished.emit()

# Determine if target(s) is single or multi
static func applyEffects(caster: CombatantScene, target, ability: ResAbility):
	if ability.current_effect == null:
		ability.current_effect = ability.basic_effects[0] # Mainly to fix follow up ability, as the projectile only runs THIS function and nothin else. Bugs later? idc.
	
	if target is Array and ability.current_effect.is_combo_effect and ability.current_effect.effect_only_combo_targets:
		target = target.filter(func(combatant): return combatant.hasStatusEffect('Combo'))
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
		if CombatGlobals.calculateDamage(
				caster, 
				target, ability.current_effect.damage_modifier, 
				ability.current_effect.can_miss, 
				ability.current_effect.can_crit, 
				'', 
				ability.current_effect.indicator_bb,
				ability.current_effect.bonus_stats
				):
				if ability.current_effect.plant_self_on_combo and target.combatant_resource.hasStatusEffect('Combo'):
					ability.current_effect.do_not_return_pos = true
		
		if (target.combatant_resource.hasStatusEffect('Combo') and ability.current_effect.is_combo_effect) and !ability.current_effect.plant_self_on_combo:
			#CombatGlobals.manual_call_indicator_bb.emit(target.combatant_resource, 'COMBO!!', 'Show', '[img]res://images/sprites/icon_combo.png[/img] [color=turquoise]')
			target.combatant_resource.getStatusEffect('Combo').removeStatusEffect()
	
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
			ability.current_effect.can_miss, 
			ability.current_effect.variation, 
			ability.current_effect.trigger_on_hits, 
			'', 
			ability.current_effect.indicator_bb,
			ability.current_effect.bonus_stats,
			ability.current_effect.use_damage_formula
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
		CombatGlobals.addStatusEffect(target, ability.current_effect.status_effect,true)
	
	elif ability.current_effect is ResHealEffect:
		CombatGlobals.calculateHealing(target, ability.current_effect.heal, ability.current_effect.use_multiplier)
	
	elif ability.current_effect is ResOnslaughtEffect:
		CombatGlobals.calculateRawDamage(
			target.combatant_resource, 
			ability.current_effect.damage, 
			caster.combatant_resource, 
			true, 
			-1, 
			false, 
			caster.combatant_resource.stat_values['dmg_variance'],
			false,
			'', 
			'',
			{},
			true
			)
		if target.combatant_resource.stat_modifiers.keys().has('block') and target.combatant_resource.hasStatusEffect('Guard') and target.combatant_resource.getStatusEffect('Guard').duration+1 <= target.combatant_resource.getStatusEffect('Guard').max_duration:
			target.combatant_resource.getStatusEffect('Guard').duration += 1
		if target.combatant_resource.isDead():
			target.animator.play('Fading')
		if ability.current_effect.target == ability.current_effect.Target.MULTI:
			for combatant in CombatGlobals.getCombatScene().getCombatantGroup('team'):
				if !combatant.isDead() and !target.combatant_resource.stat_modifiers.keys().has('block') and combatant != target.combatant_resource: 
					CombatGlobals.calculateRawDamage(
						target.combatant_resource, 
						ability.current_effect.damage, 
						caster.combatant_resource, 
						true, 
						-1, 
						false, 
						caster.combatant_resource.stat_values['dmg_variance'], 
						false,
						'', 
						'',
						{},
						true
						)

# Attack animations (Ranged, melee)
static func doAttackAnimations(caster: CombatantScene, target, ability:ResAbility, damage_effect: ResDamageEffect):
	if damage_effect.damage_type == damage_effect.DamageType.MELEE:
		await caster.moveTo(target)
		await caster.doAnimation('Cast_Melee', ability.ability_script) # SPEED UP {'anim_speed':1.5}
		await returnToPosition(damage_effect, caster)
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED:
		await caster.doAnimation('Cast_Ranged', ability.ability_script, {'target'=target,'frame_time'=0.4,'ability'=ability})
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED_PIERCING:
		await caster.doAnimation('Cast_Ranged', ability.ability_script, {'target'=null,'frame_time'=0.4,'ability'=ability})
	elif damage_effect.damage_type == damage_effect.DamageType.CUSTOM:
		if damage_effect.cast_animation['go_to_target']:
			await caster.moveTo(target)
		await caster.doAnimation(damage_effect.cast_animation['animation'], ability.ability_script)
		if damage_effect.cast_animation['go_to_target']:
			await returnToPosition(damage_effect, caster)

static func returnToPosition(damage_effect: ResDamageEffect, caster: CombatantScene):
	if damage_effect.return_pos and !damage_effect.do_not_return_pos:
		await caster.moveTo(caster.get_parent())
	if damage_effect.do_not_return_pos:
		damage_effect.do_not_return_pos = false

static func canDoCombo(effect: ResAbilityEffect, target)-> bool:
	if target is CombatantScene:
		return effect.is_combo_effect and target.combatant_resource.hasStatusEffect('Combo')
	elif target is  Array:
		target = target.filter(func(combatant): return combatant.hasStatusEffect('Combo'))
		return effect.is_combo_effect and target.size() > 0
	
	return false

# Returns true if target meets combo requirements
#static func checkDamageCombo(target: ResCombatant, effect, check_property: String='', allow_no_combo:bool=true)-> bool:
#	return (effect.has_combo_effects and effect.canCombo(target, check_property)) or (!effect.has_combo_effects and allow_no_combo)
