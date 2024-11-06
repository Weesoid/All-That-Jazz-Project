extends Label

@export var show_max = true

func _process(_delta):
	if show_max:
		text = "%s / %s" % [get_parent().value, get_parent().max_value]
	else:
		text = "%s" % snappedf(get_parent().value, 1.0)
