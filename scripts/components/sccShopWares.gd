extends Node

@export var SHOP_WARES: Array[ResItem]
@export var GOD_SHOP: bool = false

func _ready():
	if GOD_SHOP:
		enableGodShop()

func enableGodShop():
	SHOP_WARES.clear()
	var wares = OverworldGlobals.loadArrayFromPath("res://resources/items/").filter(func(item): return !OverworldGlobals.isResourcePlaceholder(item))
	SHOP_WARES.assign(wares)
