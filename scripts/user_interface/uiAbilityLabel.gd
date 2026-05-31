extends RichTextLabel
class_name AbilityLabel

func setAbility(ability:ResAbility, combatant:ResCombatant):
	text = '[right]'+ability.name.to_upper() + '\n'+ability.getPositionIcon(true, combatant is ResEnemyCombatant)
	await resized
	UIGlobals.addTooltip(
		self,
		ability.getRichDescription(),
		CustomTooltip.AnchorPreset.LEFT,
		0.0
	)
	if !ability.canUse(combatant):
		self_modulate = Color(Color.DIM_GRAY,0.5)
