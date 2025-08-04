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

# Load array of resource paths
func loadResourcePathArray(path_array):
	var out = []
	
	for path in path_array:
		if !FileAccess.file_exists(path):
			continue
		out.append(load(path))
	
	return out

# Convert array of resources into array of resource paths
func getResourcePathArray(array):
	var out = []
	for res in array:
		out.append(res.resource_path)
	
	return out

# Load dict of resources (Resource: Resource or Resource: [Resource, Resource, ...])
func loadResourcePathDict(dict:Dictionary):
	var out = {}
	for key in dict.keys():
		if !FileAccess.file_exists(key):
			continue
		if dict[key] is Array:
			out[load(key)] = loadResourcePathArray(dict[key])
		else:
			out[load(key)] = load(dict[key])
	return out

# Convert dict of resources to dict of resource paths
func getResourcePathDict(dict):
	if dict == {}:
		return {}
	
	var out = {}
	for key in dict.keys():
		if dict[key] is Array:
			out[key.resource_path] = getResourcePathArray(dict[key])
		else:
			out[key.resource_path] = dict[key].resource_path
	
	return out

func loadResourcePath(path:String):
	if FileAccess.file_exists(path):
		return load(path)
	else:
		return null

func getResourcePath(resource):
	if resource == null:
		return ''
	
	if FileAccess.file_exists(resource.resource_path):
		return resource.resource_path
	else:
		return ''

#func filterExistingResources(element):
#	return FileAccess.file_exists(element)
