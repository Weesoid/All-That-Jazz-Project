extends TextureRect
class_name StatusIcon

@onready var duration = $Duration
@onready var rank = $Duration/Rank
var attached_status: ResStatusEffect
var pooled_statuses: Array[ResStatusEffect] = []

func _ready():
	if attached_status.seperate_instances:
		pooled_statuses.append(attached_status)
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
		duration.text = str(attached_status.duration) if pooled_statuses.size() == 0 else str(getLongestDuration().duration)

func poolEffects(effect:ResStatusEffect):
	pooled_statuses.append(effect)
	setAttachedStatus()
	updateDuration()

func getLongestDuration():
	var current_longest = attached_status
	for effect in pooled_statuses:
		if effect.duration > current_longest.duration: current_longest = effect
	
	return current_longest

func setAttachedStatus():
	var longest_effect = getLongestDuration()
	if longest_effect == attached_status: return
	
	attached_status.ticked.disconnect(updateDuration)
	attached_status.expired.disconnect(queue_free)
	attached_status = longest_effect
	attached_status.ticked.connect(updateDuration)
	attached_status.expired.connect(queue_free)
