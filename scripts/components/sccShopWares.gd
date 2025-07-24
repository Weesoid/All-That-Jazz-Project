extends Node

@export var shop_wares: Array[ResItem]
@export var god_shop: bool = false

func _ready():
	if god_shop:
		enableGodShop()

func enableGodShop():
	shop_wares.clear()
	var wares = OverworldGlobals.loadArrayFromPath("res://resources/items/").filter(func(item): return !OverworldGlobals.isResourcePlaceholder(item))
	shop_wares.assign(wares)
