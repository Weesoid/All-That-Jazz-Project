extends Resource
class_name ResFactionProperties

@export var faction: CombatGlobals.Enemy_Factions
@export var patroller_properties: Array[ResPatrollerProperties]
@export var combatants_path: String
@export var music: Array[String] = []

func pickRandomSpecial():
	var specials = []
	for patroller in patroller_properties:
		if patroller is ResPatrollerPropertiesShooter and !specials.has(1):
			specials.append(1)
		elif patroller is ResPatrollerPropertiesHybrid and !specials.has(2):
			specials.append(2)
	
	print(specials)
	randomize()
	return specials.pick_random()

func getSpecials():
	return patroller_properties.filter(func(patroller): return patroller is ResPatrollerPropertiesShooter or patroller is ResPatrollerPropertiesHybrid)

func getPatrollerType(type:int):
	match type:
		0:return patroller_properties.filter(func(patroller): return !patroller is ResPatrollerPropertiesShooter and !patroller is ResPatrollerPropertiesHybrid)
		1:return patroller_properties.filter(func(patroller): return patroller is ResPatrollerPropertiesShooter)
		2:return patroller_properties.filter(func(patroller): return patroller is ResPatrollerPropertiesHybrid)

func getPatrollerProperties(type:int):
	return getPatrollerType(type).pick_random()
