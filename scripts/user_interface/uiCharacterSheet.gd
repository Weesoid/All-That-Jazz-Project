extends MarginContainer
class_name CharacterSheet

@onready var character_adjust = $CharacterAdjust

func showCharacter(character:ResPlayerCombatant):
	character_adjust.loadMemberInfo(character)
	show()
