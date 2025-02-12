static func animate(caster: CombatantScene, target: CombatantScene, ability: ResAbility):
	pass


static func applyEffects(caster: CombatantScene , target: CombatantScene, _ability: ResAbility=null):
	CombatGlobals.calculateDamage(caster, target, 2)
