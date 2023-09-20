extends ResEquippable
class_name ResWeapon

@export var EFFECT: ResAbility
@export var durability: Vector2i

func equip(combatant: ResCombatant):
	if combatant is ResPlayerCombatant:
		if EQUIPPED_COMBATANT != null or durability.x <= 0:
			unequip()
		if combatant.EQUIPMENT['weapon'] != null:
			combatant.EQUIPMENT['weapon'].unequip()
	
	EQUIPPED_COMBATANT = combatant
	combatant.EQUIPMENT['weapon'] = self
	combatant.ABILITY_SET[0] = EFFECT
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT.ABILITY_SET[0] = load("res://resources/abilities/Punch.tres")
	EQUIPPED_COMBATANT.EQUIPMENT['weapon'] = null
	EQUIPPED_COMBATANT = null

func useDurability():
	durability.x -= 1
	if durability.x <= 0:
		durability.x = 0
		print('Unequipped!')
		unequip()
	
