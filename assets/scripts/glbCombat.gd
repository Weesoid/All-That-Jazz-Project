extends Node

signal ability_executed

func emit_ability_executed():
	ability_executed.emit()

func playSingleTargetAnimation(target:ResCombatant, animation_scene):
	animation_scene.position = target.SCENE.global_position
	animation_scene.get_node('AnimationPlayer').play('Execute')
	
func calculateDamage(caster: ResCombatant, target:ResCombatant, base, scaling):
	var damage = ((base * 100) / (100+target.STAT_GRIT)) + (caster.STAT_BRAWN * scaling)
	target.STAT_HEALTH = target.STAT_HEALTH - int(damage)
	
	target.playIndicator(str('HIT -', int(damage)))
	target.updateHealth(target.STAT_HEALTH)
	target.getAnimator().play('Hit')
	await target.getAnimator().animation_finished
	target.getAnimator().play('Idle')
	
func calculateHealing(caster: ResCombatant, target:ResCombatant, base, scaling):
	var healing: int = base + (caster.STAT_WIT * scaling)
	
	if target.STAT_HEALTH + healing > target.getSprite().get_node("HealthBar").max_value:
		target.STAT_HEALTH = target.getSprite().get_node("HealthBar").max_value
	else:
		target.STAT_HEALTH = target.STAT_HEALTH + healing
	
	target.playIndicator(str('HEALED +',healing))
	target.updateHealth(target.STAT_HEALTH)
