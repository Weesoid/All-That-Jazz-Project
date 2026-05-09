extends Label

@export var show_max:bool=false

func _process(_delta):
	text = str($"..".value)
