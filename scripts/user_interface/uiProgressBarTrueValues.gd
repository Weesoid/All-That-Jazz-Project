extends Label

func _process(_delta):
	text = "%s / %s" % [get_parent().value, get_parent().max_value]
