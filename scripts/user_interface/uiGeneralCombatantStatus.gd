extends MarginContainer

@onready var char_name = $Health/CharacterName
@onready var char_health = $Health
@onready var char_effects = $Health/StatusContainer
var combatant: ResPlayerCombatant

func _process(_delta):
	char_name.text = combatant.NAME
	char_health.value = combatant.STAT_VALUES['health']
	char_health.max_value = combatant.getMaxHealth()
#	for status_effect in combatant.LINGERING_STATUS_EFFECTS:
#		char_effects.add_child(CombatGlobals.getStatusEffect(status_effect).ICON)
	if combatant.isInflicted():
		char_name.add_theme_color_override("font_color", Color.ORANGE)
		char_health.tooltip_text = combatant.getLingeringEffectsString()
	else:
		char_name.add_theme_color_override("font_color", Color.WHITE)
		char_name.tooltip_text = ''
