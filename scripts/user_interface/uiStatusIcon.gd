extends TextureRect
class_name StatusIcon

@onready var duration = $Duration
@onready var rank = $Duration/Rank
var attached_status: ResStatusEffect

func _ready():
	texture = attached_status.texture
	self_modulate = attached_status.getIconColor()
	UIGlobals.addTooltip(
		self, 
		attached_status.getDescription(),
		CustomTooltip.AnchorPreset.BOTTOM
		)
	attached_status.ticked.connect(updateDuration)
	attached_status.expired.connect(queue_free)
	updateDuration()

func updateDuration():
	if !attached_status.permanent:
		duration.text = str(attached_status.duration)
