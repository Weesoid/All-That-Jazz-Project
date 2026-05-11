# Guard code
static func applyEffects(target, status_effect:ResStatusEffect):
	if target.stat_modifiers.keys().has('block') and !target.combatant_scene.allow_block:
		CombatGlobals.resetStat(target, 'block')
#	if target.stat_values['health'] <= 0 and status_effect.apply_once:
#		CombatGlobals.calculatePercentHealing(target, 0.1,false)
	target.combatant_scene.setBlocking(true)
	status_effect.attached_data = 1
#	if !target.hasStatusEffect('Guard Break'):
#		if target.stat_values['health'] <= 0 and status_effect.apply_once:
#			CombatGlobals.calculatePercentHealing(target, 0.1,false)
#		target.combatant_scene.setBlocking(true)
#		status_effect.attached_data = 1
#	else:
#		status_effect.removeStatusEffect()

static func applyOnHitEffects(target, caster, _value, status_effect):
	if target is ResPlayerCombatant and target.stat_modifiers.keys().has('block'):
		CombatGlobals.getCombatScene().battleFlash('Flash', Color.WHITE)
		#CombatGlobals.manual_call_indicator.emit(target, '[img]'+str(status_effect.texture.get_path())+'[/img] Blocked!', 'Resist')
		if target is ResPlayerCombatant and status_effect.attached_data == 1:
			CombatGlobals.addTension(1,target.combatant_scene)
			status_effect.attached_data = 0
	else:
		target.combatant_scene.block_timer.start(0.8)
	
	if target != CombatGlobals.getCombatScene().active_combatant and !status_effect.afflicted_combatant.isImmobilized() and ((target is ResPlayerCombatant and target.stat_modifiers.has('block')) or target is ResEnemyCombatant):
		doRiposte(target,caster,status_effect)

static func endEffects(target, _status_effect: ResStatusEffect):
	target.combatant_scene.setBlocking(false)
	if target.stat_modifiers.keys().has('block') and !target.combatant_scene.allow_block:
		CombatGlobals.resetStat(target, 'block')
	if !CombatGlobals.getCombatScene().isCombatValid():
		return
	
	if !target.hasStatusEffect('Guard Break'):
		CombatGlobals.addStatusEffect(target, 'GuardBreak')
	else:
		CombatGlobals.removeStatusEffect(target, 'Guard Break')

# Riposte code
static func doRiposte(target, caster, status_effect):
	var riposte_anim = determineRiposte(target, caster)
	if riposte_anim == 'Cast_Melee':
		target.combatant_scene.doAnimation(riposte_anim, status_effect.status_script, {'anim_speed'=1.5})
	else:
		target.combatant_scene.doAnimation(riposte_anim, status_effect.status_script, {'target'=caster.combatant_scene,'frame_time'=0.7,'ability'=null,'anim_speed'=2.0})

static func determineRiposte(target, caster):
	var distance = target.combatant_scene.global_position.distance_to(caster.combatant_scene.global_position)
	if distance > 60:
		return 'Cast_Ranged'
	else:
		return 'Cast_Riposte' if 'Cast_Riposte' in target.combatant_scene.animator.get_animation_list() else 'Cast_Melee'

static func applyAbilityEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	var caster_riposte = caster.combatant_resource.riposte_effect
	var message_icon = '[img '+SettingsGlobals.ui_colors['up-bb-nobracket']+']res://images/status_icons/icon_riposte.png[/img]'+SettingsGlobals.ui_colors['up-bb']
	if caster_riposte != null:
		CombatGlobals.calculateDamage(
			caster, 
			target, 
			caster_riposte.damage_modifier,
			#caster_riposte.can_miss,
			caster_riposte.can_crit,
			'',
			message_icon,
			caster_riposte.bonus_stats
		)
	else:
		CombatGlobals.calculateDamage(
			caster, 
			target, 
			0.5,
			#true,
			true,
			'',
			message_icon,
		)
