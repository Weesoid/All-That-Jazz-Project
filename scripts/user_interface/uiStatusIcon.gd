extends TextureRect
class_name StatusIcon

@onready var duration = $Duration
@onready var rank = $Duration/Rank
@onready var pulser = $Pulser
var attached_status: ResStatusEffect
var pooled_statuses: Array[ResStatusEffect] = []

func _ready():
	pulser.modulate=Color.TRANSPARENT
	if attached_status.seperate_instances:
		pooled_statuses.append(attached_status)
	texture = attached_status.texture
	self_modulate = attached_status.getIconColor()
	attached_status.ticked.connect(updateDuration)
	attached_status.expired.connect(queue_free)
	updateDuration()

func updateDuration():
	if !attached_status.permanent or (attached_status.remove_style == ResStatusEffect.RemoveStyle.TICK_DOWN and attached_status.max_duration > 1):
		if int(duration.text) != attached_status.duration:
			pulse(Color.WHITE)
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

func pulse(color:Color):
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(pulser,"modulate",color, 0.1)
	tween.tween_property(pulser,"modulate",Color.TRANSPARENT, 0.5)

func _on_tree_entered():
	modulate = Color.TRANSPARENT
	if attached_status.afflicted_combatant.isDead(true): return
	await get_tree().process_frame
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	position.y -= 24
	tween.tween_property(self, "position", position+Vector2(0,24),0.25)
	tween.tween_property(self, "modulate", Color.WHITE,0.25)
