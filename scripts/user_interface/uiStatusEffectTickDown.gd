extends Label

@onready var rank = $Rank
var attached_status: ResStatusEffect

func _process(_delta):
	text = str(attached_status.duration)
	if attached_status.PERMANENT: 
		hide()
#	if attached_status.MAX_RANK != 0:
#		if attached_status.MAX_RANK == attached_status.current_rank:
#			rank.text = 'MAX'
#		else:
#			rank.text = str(attached_status.current_rank)
