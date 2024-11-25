extends Node2D
class_name CombatantScene

@onready var animator = $AnimationPlayer
@onready var collision = $CollisionShape2D
@export var combatant_resource: ResCombatant

var idle_animation: String = 'Idle'
var hit_script: GDScript

func moveTo(target, duration:float=0.25, offset:Vector2=Vector2(0,0), ignore_dead:bool=false):
	if combatant_resource.isDead() and !ignore_dead: 
		return
	if target is CombatantScene: 
		target = target.combatant_resource
	if target is ResCombatant:
		target = target.SCENE
		if target.combatant_resource is ResEnemyCombatant: 
			offset = Vector2(-40,0)
		else:
			offset = Vector2(40,0)
	
	var tween = create_tween()
	tween.tween_property(self, 'global_position', Vector2(target.global_position.x, -14) + offset, duration)
	await tween.finished
	if combatant_resource.isDead() and combatant_resource is ResEnemyCombatant:
		playIdle('KO')
	else:
		playIdle()

func doAnimation(animation: String, script: GDScript=null, data:Dictionary={}):
	#animator.play("RESET")
	if combatant_resource.isDead() and !['Fading, KO'].has(animation) or animation == '': return
	if !animator.get_animation_list().has(animation): animation = 'Cast_Misc'
	
	if script != null: hit_script = script
	if animation == 'Cast_Ranged':
		setProjectileTarget(data['target'], data['frame_time'], data['ability'])
	if data.keys().has('anim_speed'):
		animator.play(animation, -1, data['anim_speed'])
	else:
		animator.play(animation, -1)
	await animator.animation_finished
	if CombatGlobals.getCombatScene().has_node('Projectile'): 
		await CombatGlobals.getCombatScene().get_node('Projectile').tree_exited
		
	playIdle()
	hit_script = null
	
	if (animation.contains('Melee') or animation.contains('Ranged')) and !CombatGlobals.getCombatScene().onslaught_mode:
		if animation.contains('Melee'):
			await get_tree().create_timer(0.1).timeout
		elif animation.contains('Ranged'):
			await get_tree().create_timer(0.25).timeout

func playIdle(new_idle:String=''):
	if new_idle != '':
		idle_animation = new_idle
	
	animator.play(idle_animation)

func setProjectileTarget(target: CombatantScene, frame_time: float, ability: ResAbility, animation:String="Cast_Ranged"):
	var anim: Animation = animator.get_animation(animation)
	if anim.find_track(".", Animation.TYPE_METHOD) != null:
		anim.remove_track(anim.find_track(".", Animation.TYPE_METHOD))
	var track_index = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track_index, ".")
	anim.track_insert_key(track_index, frame_time, {
	"method": "shootProjectile",
	"args": [target, ability],
	}, 0)

func shootProjectile(target: CombatantScene, ability: ResAbility):
	var projectile = load("res://scenes/entities_disposable/ProjectileBattles.tscn").instantiate()
	projectile.hit_script = hit_script
	projectile.ability = ability
	projectile.name = 'Projectile'
	projectile.target = target
	projectile.SHOOTER = self
	projectile.global_position = global_position
	if combatant_resource is ResEnemyCombatant and scale.x > 0:
		projectile.rotation_degrees = 180
	CombatGlobals.getCombatScene().add_child(projectile)

func _on_hit_box_body_entered(body):
	if hit_script != null and body != self and body is CombatantScene and !CombatGlobals.isSameCombatantType(self, body): 
		hit_script.applyEffects(self, body, CombatGlobals.getCombatScene().selected_ability)

func _to_string():
	return combatant_resource.NAME
