extends Label

var attached_status: ResStatusEffect

func _process(delta):
	text = str(attached_status.duration)
