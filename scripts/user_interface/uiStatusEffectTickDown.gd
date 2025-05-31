extends Label

@onready var rank = $Rank
var flicker_tween: Tween
var attached_status: ResStatusEffect

func _ready():
	flicker_tween = create_tween().set_loops()
	#flicker_tween.tween_property(get_parent(),'modulate', Color.TRANSPARENT, 0.25).from(Color.WHITE)
	flicker_tween.stop()

func _process(_delta):
#	if !attached_status.TICK_PER_TURN:
#		text = str(attached_status.duration-1)
#	else:
	text = str(attached_status.duration)
#	if attached_status.duration <= 1 and !attached_status.TICK_PER_TURN:
#		get_parent().hide()
	if attached_status.PERMANENT and attached_status.MAX_DURATION == 0: 
		hide()
	if attached_status.MAX_RANK != 0:
		rank.text = str(attached_status.current_rank)
	if attached_status.duration == 1 and !attached_status.PERMANENT and CombatGlobals.getCombatScene().active_combatant == attached_status.afflicted_combatant and !flicker_tween.is_running():
		flicker_tween.tween_property(get_parent(),'self_modulate', Color.TRANSPARENT, 1.5).from(Color.WHITE)
		flicker_tween.play()
	elif flicker_tween.is_running() and attached_status.duration > 1 and !attached_status.PERMANENT:
		get_parent().self_modulate = Color.WHITE
		flicker_tween.stop()
	if CombatGlobals.getCombatScene().ui_inspect_target.visible:
		self_modulate = Color.TRANSPARENT
		if attached_status.current_rank == attached_status.MAX_RANK or attached_status.MAX_RANK == 0:
			rank.modulate = Color.YELLOW
		else:
			rank.modulate = Color.WHITE
	else:
		self_modulate = Color.WHITE
		rank.modulate = Color.TRANSPARENT
	
