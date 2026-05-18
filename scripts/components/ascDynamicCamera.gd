extends Camera2D
class_name DynamicCamera

@onready var ui_layer = $UI
@onready var color_overlay = $UI/ColorOverlay

var shake_strength: float = 0.0
var shake_speed: float = 0.0
var flashers = {}

func _ready():
	var ui_layer_ordered = ui_layer.get_children()
	ui_layer_ordered.reverse()
	for child in ui_layer_ordered:
		if child.name.contains('Flasher'): flashers[child] = false

func _process(delta):
	if shake_strength != 0:
		shake_strength = lerpf(shake_strength, 0, shake_speed * delta)
		offset = Vector2(randf_range(-shake_strength,shake_strength), randf_range(-shake_strength,shake_strength))

func shake(strength: float, speed: float):
	if CombatGlobals.inCombat() and CombatGlobals.getCombatScene().rebuking:
		return
	
	shake_speed = speed
	shake_strength = strength

func flash(color:Color,alpha:float=1.0, fade_in:float=0.1, fade_out:float=0.25):
	for flash in flashers:
		if flashers[flash]: continue
		
		flashers[flash]=true
		var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(func():flashers[flash]=false)
		tween.tween_property(flash,'color',Color(color,alpha),fade_in)
		tween.tween_property(flash,'color',Color.TRANSPARENT,fade_out)
		await tween.finished
		return

func showOverlay(color:Color, duration:float=0.25, alpha:float=1.0):
	var tween = get_tree().create_tween()
	tween.tween_property(color_overlay,'color',Color(color,alpha if color != Color.TRANSPARENT else 0),duration)
	await tween.finished

#func showOverlay(color:Color,alpha:float, duration:float=0.25):
#	for overlay in overlay_tweens:
#		if overlay_tweens[overlay]:
#			overlay_tweens[overlay]=true
#			var tween = get_tree().create_tween()
#			#tween.finished.connect(func():overlay_tweens[overlay]=false)
#			tween.tween_property(overlay,'color',Color(color,alpha),duration)
#			await tween.finished
#			return
