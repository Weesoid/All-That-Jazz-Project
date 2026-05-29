extends Control
class_name CombatInspector

@onready var attributes = $PanelContainer/MarginContainer/AttributeView

func setCombatant(combatant:ResCombatant):
	attributes.setCombatant(combatant)
