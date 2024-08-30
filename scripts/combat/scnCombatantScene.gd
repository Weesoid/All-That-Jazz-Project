extends Node2D
class_name CombatantScene

@onready var animator = $AnimationPlayer
@export var combatant_resource: ResCombatant

var idle_animation: String = 'Idle'
var hit_script: GDScript

func moveTo(target, duration:float=0.25, offset:Vector2=Vector2(0,0)):
	if target is CombatantScene: target = target.combatant_resource
	var tween = create_tween()
	if target is ResCombatant:
		target = target.SCENE
		if target.combatant_resource is ResEnemyCombatant: 
			offset = Vector2(-40,0)
		else:
			offset = Vector2(40,0)
	tween.tween_property(self, 'global_position', target.global_position + offset, duration)
	await tween.finished

func doAnimation(animation: String='Cast_Weapon', script: GDScript=null, idle:bool=true, data:Dictionary={}):
	if script != null: hit_script = script
	z_index = 99
	if animation == 'Cast_Ranged': 
		setProjectileTarget(data['target'], data['frame_time'])
	animator.play(animation)
	await animator.animation_finished
	if CombatGlobals.getCombatScene().has_node('Projectile'): 
		await CombatGlobals.getCombatScene().get_node('Projectile').tree_exited
	animator.play('RESET')
	animator.play(idle_animation)
	await get_tree().create_timer(0.5)
	hit_script = null
	z_index = 0

func setProjectileTarget(target: CombatantScene, frame_time: float):
	var anim: Animation = animator.get_animation("Cast_Ranged")
	if anim.find_track(".", Animation.TYPE_METHOD) != null:
		anim.remove_track(anim.find_track(".", Animation.TYPE_METHOD))
	var track_index = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track_index, ".")
	anim.track_insert_key(track_index, .700, {
	"method": "shootProjectile",
	"args": [target],
	}, 0)

func shootProjectile(target: CombatantScene):
	var projectile = load("res://scenes/entities_disposable/ProjectileBattles.tscn").instantiate()
	projectile.hit_script = hit_script
	projectile.name = 'Projectile'
	projectile.target = target
	projectile.SHOOTER = self
	projectile.global_position = global_position
	if combatant_resource is ResEnemyCombatant:
		projectile.rotation_degrees = 180
	CombatGlobals.getCombatScene().add_child(projectile)

func _on_hit_box_body_entered(body):
	if hit_script != null and body != self: 
		hit_script.applyEffects(body, self)

func _to_string():
	return combatant_resource.NAME
