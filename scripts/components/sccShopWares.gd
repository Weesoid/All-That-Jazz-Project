extends Node

@export var SHOP_WARES: Array[ResItem]
@export var GOD_SHOP: bool = false

func _ready():
	if GOD_SHOP:
		enableGodShop()

func enableGodShop():
	SHOP_WARES.clear()
	var path = "res://resources/items/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			SHOP_WARES.append(load(path+'/'+file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
