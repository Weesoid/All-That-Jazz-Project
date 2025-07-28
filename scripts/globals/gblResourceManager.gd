extends Node

#func _ready():
#	loadAutonamedResources()

func loadFromPath(path:String, key:String, exstension:String='.tres'):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == key+exstension:
				return load(path+'/'+file_name)
	else:
		print("An error occurred when trying to access the path.")
		print(path)

func loadArrayFromPath(path:String, filter=null)-> Array:
	var out = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			out.append(load(path+'/'+file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	if filter != null:
		out = out.filter(filter)
	
	return out
