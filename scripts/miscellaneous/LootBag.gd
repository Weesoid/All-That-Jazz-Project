extends Node2D

@onready var interaction = $Interaction

func setLoot(loot: Array[ResItem]):
	interaction.loot = loot
