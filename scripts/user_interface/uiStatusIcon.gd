extends TextureRect
class_name StatusIcon
@onready var duration = $Duration
@onready var rank = $Duration/Rank
var flicker_tween: Tween
var attached_status: ResStatusEffect

func _ready():
	flicker_tween = create_tween().set_loops()
	flicker_tween.stop()
	texture = attached_status.texture
	self_modulate = attached_status.getIconColor()
	tooltip_text = attached_status.getDescription()
	

func _process(_delta):
	if attached_status.permanent and attached_status.duration <= 1: 
		duration.text = ''
	else:
		duration.text = str(attached_status.duration)
	if attached_status.max_rank != 0:
		rank.text = str(attached_status.current_rank)
	if flicker_tween.is_valid() and attached_status.duration == 1 and !attached_status.permanent and CombatGlobals.getCombatScene().active_combatant == attached_status.afflicted_combatant and !flicker_tween.is_running():
		flicker_tween.tween_property(self,'modulate', Color.TRANSPARENT, 1.5).from(Color.WHITE)
		flicker_tween.play()
	elif flicker_tween.is_running() and attached_status.duration > 1 and !attached_status.permanent:
		self_modulate = Color.WHITE
		flicker_tween.stop()
	if CombatGlobals.getCombatScene().ui_inspect_target.visible:
		duration.self_modulate = Color.TRANSPARENT
		if attached_status.current_rank == attached_status.max_rank or attached_status.max_rank == 0:
			rank.modulate = Color.YELLOW
		else:
			rank.modulate = Color.WHITE
	else:
		duration.self_modulate = Color.WHITE
		rank.modulate = Color.TRANSPARENT

func _on_tree_exited():
	flicker_tween.kill()
