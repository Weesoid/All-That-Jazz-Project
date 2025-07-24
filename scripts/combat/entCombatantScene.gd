extends Node2D
class_name CombatantScene

@onready var animator = $AnimationPlayer
@onready var collision = $CollisionShape2D
@export var combatant_resource: ResCombatant

var idle_animation: String = 'Idle'
#var rank_position: Vector2
var hit_script: GDScript


func moveTo(target, duration:float=0.25, offset:Vector2=Vector2(0,0), ignore_dead:bool=false):
	if cannotAct() and !ignore_dead: 
		return
#	await get_tree().process_frame
#	if CombatGlobals.getCombatScene().has_node('QTE'):
#		await CombatGlobals.qte_finished
#		await CombatGlobals.getCombatScene().get_node('QTE').tree_exited
	if target is CombatantScene: 
		target = target.combatant_resource
	if target is ResCombatant:
		target = target.combatant_scene
		if target.combatant_resource is ResEnemyCombatant: 
			offset = Vector2(-40,0)
		else:
			offset = Vector2(40,0)
	
	combatant_resource.resetSprite()
	var tween = create_tween()
	tween.tween_property(self, 'global_position', Vector2(target.global_position.x, -14) + offset, duration)
	await tween.finished
	if combatant_resource.isDead() and combatant_resource is ResEnemyCombatant:
		playIdle('KO')
	else:
		playIdle()
	
	#is_

func doAnimation(animation: String, script: GDScript=null, data:Dictionary={}):
	#animator.play("RESET")
	if cannotAct() and !['Fading, KO'].has(animation) or animation == '': 
		await get_tree().create_timer(0.25).timeout
		return
#	if CombatGlobals.getCombatScene().has_node('QTE'):
#		await CombatGlobals.qte_finished
#		await CombatGlobals.getCombatScene().get_node('QTE').tree_exited
	if !animator.get_animation_list().has(animation): animation = 'Cast_Misc'
	combatant_resource.stopBreatheTween()
	
	if script != null: hit_script = script
	if animation == 'Cast_Ranged' and data.has('target') and CombatGlobals.inCombat():
		setProjectileTarget(data['target'], data['frame_time'], data['ability'])
	if data.keys().has('anim_speed'):
		animator.play(animation, -1, data['anim_speed'])
	else:
		animator.play(animation, -1)
	await animator.animation_finished
	if CombatGlobals.inCombat() and CombatGlobals.getCombatScene().has_node('Projectile'): 
		await CombatGlobals.getCombatScene().get_node('Projectile').tree_exited
	#animator.play('RESET')
	if !data.has('skip_pause') or (CombatGlobals.inCombat() and !CombatGlobals.getCombatScene().onslaught_mode):
		await get_tree().create_timer(0.25).timeout
	if !data.has('skip_idle'):
		playIdle()
	hit_script = null

func cannotAct()-> bool:
	return combatant_resource.isDead() and !combatant_resource.hasStatusEffect('Fading')

func playIdle(new_idle:String=''):
	if new_idle != '':
		idle_animation = new_idle
	combatant_resource.resetSprite()
	combatant_resource.startBreatheTween(false)
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
	projectile.shooter = self
	#projectile.SPEED = 1250.0
	if combatant_resource.bullet_texture != null:
		projectile.get_node('Sprite2D').texture = combatant_resource.bullet_texture
	projectile.global_position = global_position
	if combatant_resource is ResEnemyCombatant and scale.x > 0:
		projectile.rotation_degrees = 180
	CombatGlobals.getCombatScene().add_child(projectile)

func _on_hit_box_body_entered(body):
	if hit_script != null and body != self and body is CombatantScene and !CombatGlobals.isSameCombatantType(self, body): 
		hit_script.applyEffects(self, body, CombatGlobals.getCombatScene().selected_ability)

func _to_string():
	return combatant_resource.name

func _exit_tree():
	if combatant_resource.scale_tween != null and combatant_resource.pos_tween != null:
		combatant_resource.scale_tween.kill()
		combatant_resource.pos_tween.kill()
		combatant_resource.scale_tween = null
		combatant_resource.pos_tween = null
		combatant_resource.resetSprite()
