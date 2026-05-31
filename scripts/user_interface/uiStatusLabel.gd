extends RichTextLabel
class_name StatusEffectLabel

func setStatusEffect(status_effect:ResStatusEffect, combatant:ResCombatant):
	text = '[table=2]
			[cell]%s[/cell]
			[cell]%s[/cell]
			[/table]' % [status_effect.name, status_effect.getMessageIcon()]
	UIGlobals.addTooltip(
		self, 
		status_effect.getDescription(), 
		CustomTooltip.AnchorPreset.LEFT,
		0.0,
		true
		)
