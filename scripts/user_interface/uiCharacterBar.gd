extends Control
class_name CharacterBara

var preferred_aliases = {
	'John Huck': 'Huck'
}

@onready var character_name = $Healthbar/Name
@onready var character_portrait = $CharacterPortrait/CharacterFace
@onready var character_health = $Healthbar

func setCharacter(combatant:ResPlayerCombatant):
	if combatant.preferred_alias != '':
		character_name.text = combatant.preferred_alias
	else:
		character_name.text = combatant.name.split(' ')[0]
	character_portrait.texture = combatant.character_portrait
	character_health.value = combatant.stat_values['health']
	character_health.max_value = combatant.getMaxHealth()
