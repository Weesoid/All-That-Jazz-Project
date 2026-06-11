extends RichTextLabel
class_name StatusEffectLabel

func setStatusEffect(status_effect:ResStatusEffect, combatant:ResCombatant):
	text = '[table=3]
			[cell]%s[/cell]
			[cell]%s[/cell]
			[cell]%s[/cell]
			[/table]' % [
				status_effect.name,
				'('+str(status_effect.duration)+' Turns)' if !status_effect.permanent else '',
				status_effect.getMessageIcon()]
	UIGlobals.addTooltip(
		self, 
		status_effect.getDescription(), 
		CustomTooltip.AnchorPreset.LEFT,
		0.2,
		true
		)
