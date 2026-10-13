# Cast animations, gap closing, etc.
static func animate(caster: CombatantScene, target, ability:ResAbility):
	for effect in ability.action_sequence:
		ability.current_action = effect
		var check_target = target[0] if target is Array else target.combatant_resource
		if !ability.current_action.conditionPassed(check_target): 
			continue
		
		if effect.animate_on == 1:
			await playAnimation(ability, caster)
		if effect.sound_effect != null: 
			OverworldGlobals.playSound(effect.resource_path)
		
		if effect is ResAttackAction:
			await doAttackAnimations(caster, target, ability, effect)
		
		elif effect is ResDirectDamageAction:
			if effect.cast_animation != '': await caster.doAnimation(effect.cast_animation)
			await applyAbilityEffects(caster, target, ability)
		
		elif effect is ResApplyStatusAction:
			if caster != null:
				await caster.doAnimation(effect.cast_animation)
			await applyAbilityEffects(caster, target, ability)
		
		elif effect is ResMoveAction:
			var temp_target = caster.combatant_resource if effect.Target.CASTER else target.combatant_resource
			if effect.direction == effect.Direction.FORWARD:
				CombatGlobals.getCombatScene().moveCombatant(temp_target, -1, effect.move_count)
			elif effect.direction == effect.Direction.BACK:
				CombatGlobals.getCombatScene().moveCombatant(temp_target, 1, effect.move_count)
			await CombatGlobals.getCombatScene().move_finished
	
		elif effect is ResHealAction:
			await caster.doAnimation(effect.cast_animation)
			if ability.current_action.base_heal > 0: 
				CombatGlobals.calculateHealing(target, ability.current_action.base_heal, ability.current_action.use_multiplier)
			if ability.current_action.percent_heal > 0.0: 
				CombatGlobals.calculatePercentHealing(target.combatant_resource, ability.current_action.percent_heal, ability.current_action.use_multiplier)
		
		elif effect is ResHealResolveAction:
			CombatGlobals.healResolve(target.combatant_resource, effect.amount)
		
		elif effect is ResCommandAbilityAction:
			CombatGlobals.execute_ability.emit(target, effect.ability)
			await CombatGlobals.get_tree().create_timer(0.5).timeout
		
		elif effect is ResAddTPAction:
			CombatGlobals.addTension(effect.add_amount, caster.combatant_resource, target.combatant_resource)
			await applyAbilityEffects(caster, target, ability)
		
		elif ability.current_action is ResChangeIdleAction and target.temporary_idle != ability.current_action.idle_name:
			target.temporary_idle = ability.current_action.idle_name
			target.playIdle()
		
		elif ability.current_action is ResStatModifierAction:
			target.combatant_resource.addTemporaryModifer(
				ability.name, 
				ability.current_action.duration,
				ability.current_action.getModifications(),
				ability.current_action.stacks,
				ability.current_action.duration_type == ResStatModifierAction.DurationType.BATTLE,
				ability.current_action.resistable
				)
		
		elif ability.current_action is ResCleanseAction:
			CombatGlobals.removeStatusEffect(target.combatant_resource, ability.current_action.cleanse_status.name)
		
		elif ability.current_action is ResDotAction:
			var dot_data = ability.current_action.getDot(target.combatant_resource)
			CombatGlobals.addStatusEffect(target.combatant_resource, dot_data[0], false, dot_data[1])
		
	await CombatGlobals.getCombatScene().get_tree().process_frame
	CombatGlobals.ability_finished.emit()

# Determine if target(s) are single or multi then apply ability effects
static func applyAbilityEffects(caster: CombatantScene, target, ability: ResAbility):
	if ability.current_action == null:
		ability.current_action = ability.action_sequence[0] # Mainly to fix follow up ability, as the projectile only runs THIS function and nothin else. Bugs later? idc.
	
#	if target is Array and ability.current_action.is_combo_effect and ability.current_action.effect_only_combo_targets:
#		target = target.filter(func(combatant): return combatant.hasStatusEffect('Combo'))
	if target is Array:
		for t in target: 
			applyToTarget(caster, t, ability)
			if ability.current_action.animate_on == 0: 
				await playAnimation(ability, t)
	else:
		applyToTarget(caster, target, ability)
		if ability.current_action.animate_on == 0: 
			await playAnimation(ability, target)

static func playAnimation(ability: ResAbility, target):
	if target is CombatantScene:
		target = target.combatant_resource
	
	if ability.current_action.animation != null and ability.current_action.animation_time >= 0.0:
		await CombatGlobals.playAbilityAnimation(target, ability.current_action.animation, ability.current_action.animation_time)
	elif ability.current_action.animation != null:
		CombatGlobals.playAbilityAnimation(target, ability.current_action.animation, ability.current_action.animation_time)

# Combat values calculations (damage, healing, etc.) APPLIES ON ATTACK HITBOX
static func applyToTarget(caster, target, ability: ResAbility):
	if ability.current_action is ResAttackAction:
		CombatGlobals.calculateDamage(
				caster, 
				target, 
				ability.current_action.damage_modifier, 
				ability.current_action.can_crit, 
				'', 
				ability.current_action.indicator_bb,
				ability.current_action.getAttackBonuses(target.combatant_resource)
				)
#		if ability.current_action.plant_self_on_combo and target.combatant_resource.hasStatusEffect('Combo'):
#			ability.current_action.do_not_return_pos = true
		
#		if (target.combatant_resource.hasStatusEffect('Combo') and ability.current_action.is_combo_effect): #and !ability.current_action.plant_self_on_combo:
#			#CombatGlobals.manual_call_indicator_bb.emit(target.combatant_resource, 'COMBO!!', 'Show', '[img]res://images/sprites/icon_combo.png[/img] [color=turquoise]')
#			target.combatant_resource.getStatusEffect('Combo').removeStatusEffect()
	
	elif ability.current_action is ResDirectDamageAction:
		if !ability.current_action.use_caster:
			caster = null
		else:
			caster = caster.combatant_resource
		if target is CombatantScene:
			target = target.combatant_resource
		CombatGlobals.calculateRawDamage(
			target, 
			ability.current_action.damage,
			caster, 
			ability.current_action.can_crit, 
			ability.current_action.crit_chance, 
			ability.current_action.variation, 
			ability.current_action.trigger_on_hits, 
			'', 
			ability.current_action.indicator_bb,
			ability.current_action.bonus_stats
			)
	
	elif ability.current_action is ResApplyStatusAction:
		if ability.current_action.target == ability.current_action.Target.TARGET:
			if target is CombatantScene:
				target = target.combatant_resource
		elif ability.current_action.target == ability.current_action.Target.CASTER:
			if target is CombatantScene:
				target = caster.combatant_resource
			else:
				target = caster
		CombatGlobals.addStatusEffect(
			target, 
			ability.current_action.status_effect,
			ability.current_action.guaranteed,
			{'bonus_duration': ability.current_action.add_duration}
			)
	
#	elif ability.current_action is ResHealAction:
#		if ability.current_action.base_heal > 0: 
#			CombatGlobals.calculateHealing(target, ability.current_action.base_heal, ability.current_action.use_multiplier)
#		if ability.current_action.percent_heal > 0.0: 
#			CombatGlobals.calculatePercentHealing(target.combatant_resource, ability.current_action.percent_heal, ability.current_action.use_multiplier)
		
# Attack animations (Ranged, melee)
static func doAttackAnimations(caster: CombatantScene, target, ability:ResAbility, damage_effect: ResAttackAction):
	var caster_position = caster.global_position
	var caster_rank_position = CombatGlobals.getCombatScene().getRankPosition(caster.combatant_resource)
	var caster_rank = CombatGlobals.getCombatScene().getCombatantPosition(caster.combatant_resource)
	var animation_data = {}
	if target is Array[ResCombatant]:
		animation_data['target_count'] = target.size()
	
	if damage_effect.cast_animation['animation'] != '':
		if damage_effect.cast_animation['go_to_target']:
			await caster.moveTo(target)
		await caster.doAnimation(damage_effect.cast_animation['animation'], ability.ability_script, animation_data)
		if damage_effect.cast_animation['go_to_target']:
			returnToPosition(damage_effect, caster)
	
	elif damage_effect.damage_type == damage_effect.DamageType.MELEE or (damage_effect.damage_type == damage_effect.DamageType.ADAPTIVE and caster_rank <= 1):
		await caster.moveTo(target)
		await caster.doAnimation(pickAnimation(caster, 'Melee'), ability.ability_script, animation_data) # SPEED UP {'anim_speed':1.5}
		returnToPosition(damage_effect, caster)
	
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED or (damage_effect.damage_type == damage_effect.DamageType.ADAPTIVE and caster_rank >= 2):
		#animation_data['projectile_texture'] = ability.current_action.projectile_texture
		if caster_position != caster_rank_position:
			await returnToPosition(damage_effect, caster)
		await caster.doAnimation(pickAnimation(caster, 'Ranged'), ability.ability_script, 
			{
				'target'=target,
				'frame_time'=0.4,
				'ability'=ability, 
				'projectile_texture'=ability.current_action.projectile_texture
			}
		)
	
	elif damage_effect.damage_type == damage_effect.DamageType.RANGED_PIERCING:
		#animation_data['projectile_texture'] = ability.current_action.projectile_texture
		if caster_position != caster_rank_position:
			await returnToPosition(damage_effect, caster)
		await caster.doAnimation(pickAnimation(caster, 'Ranged'), ability.ability_script, 
			{
				'target'=null,
				'frame_time'=0.4,
				'ability'=ability, 
				'projectile_texture'=ability.current_action.projectile_texture
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

static func returnToPosition(damage_effect: ResAttackAction, caster: CombatantScene):
	var turn_order = CombatGlobals.getCombatScene().getTurnOrder()
	var caster_resource = caster.combatant_resource
	if !damage_effect.return_pos or (turn_order.has(caster_resource) and turn_order.size() > 2 and turn_order[1] == caster_resource and damage_effect.damage_type == ResAttackAction.DamageType.MELEE): 
		return
	await caster.moveTo(CombatGlobals.getCombatScene().getRankPosition(caster_resource))
#	if damage_effect.do_not_return_pos:
#		damage_effect.do_not_return_pos = false

#static func canDoCombo(effect: ResAbilityAction, target)-> bool:
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
