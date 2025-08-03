extends Node

@export var shop_wares: Array[ResItem]
@export var god_shop: bool = false

func _ready():
	if god_shop:
		enableGodShop()

func enableGodShop():
	shop_wares.clear()
	var wares = ResourceGlobals.loadArrayFromPath("res://resources/items/")#.filter(func(item): return !OverworldGlobals.isResourcePlaceholder(item) and ((item is ResWeapon and item.effect != null) or !item is ResWeapon))
	shop_wares.assign(wares)
