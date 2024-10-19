extends Label

var attached_status: ResStatusEffect

func _process(_delta):
	text = str(attached_status.duration)
	if attached_status.PERMANENT: hide()
