extends ProgressBar

@export var HEALTH: int

signal depleted_health

func _process(_delta):
	value = HEALTH

func damageHealth(damage):
	HEALTH = HEALTH - damage
	if HEALTH < 0:
		depleted_health.emit()
