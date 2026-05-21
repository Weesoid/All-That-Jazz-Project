extends Label

@export var show_max = true

# FIX LATER
#func _ready():
#	await get_tree().process_frame
#	var parent_bar = get_parent()
#	update(parent_bar.value)
#	parent_bar.value_changed.connect(update)
#
#func update(value):
#	print(get_parent().max_value)
#	text = "%s/%s" % [value, get_parent().max_value] if show_max else "%s" % snappedf(get_parent().value, 1.0)

func _process(_delta):
	var val = snappedf(get_parent().value, 1.0)
	if show_max:
		text = "%s/%s" % [val, get_parent().max_value]
	else:
		text = "%s" % snappedf(val, 1.0)
