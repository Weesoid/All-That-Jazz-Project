extends Node2D
class_name CombatantScene

const HITBOX_OFFSET_POSITION = Vector2(32,0)
const HURTBOX_RADIUS = 12
const HURTBOX_HEIGHT = 48

@onready var animator = $AnimationPlayer
@onready var collision = $CollisionShape2D
@onready var hitbox = $HitBox
@onready var hitbox_shape = $HitBox/CollisionShape2D
@onready var sprite = $Sprite2D
@export var combatant_resource: ResCombatant

var idle_animation: String = 'Idle'
var temporary_idle:String
#var rank_position: Vector2
var hit_script: GDScript


func _ready():
	initializeShapes()


func initializeShapes():
	if combatant_resource is ResEnemyCombatant:
		sprite.flip_h = true
	collision.shape.radius = HURTBOX_RADIUS
	collision.shape.height = HURTBOX_HEIGHT
	hitbox.position = Vector2.ZERO
	hitbox_shape.shape.size = Vector2(32,32)

func moveTo(target, duration:float=0.25, offset:Vector2=Vector2(0,0), ignore_dead:bool=false):
	if cannotAct() and !ignore_dead: 
		return
	
	# WHAT THE FUCK IS THIS
	if target is CombatantScene: 
		target = target.combatant_resource
	if target is ResCombatant or target is Array[ResCombatant]:
		offset = Vector2(40,0)
	if target is ResEnemyCombatant or (target is Array and target[0] is ResEnemyCombatant):
		offset *= -1
	if target is ResCombatant:
		target = target.combatant_scene
	
	combatant_resource.resetSprite()
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	var destination
	if target is Node2D:
		destination = Vector2(target.global_position.x, -16) + offset 
	elif target is Array[ResCombatant]:
		var target_pos = target[0].combatant_scene.global_position
		destination = Vector2(target_pos.x, -16) + offset 
	elif target is Vector2:
		destination = target
	
	tween.tween_property(self, 'global_position', destination, duration)
	await tween.finished
	#if combatant_resource.isDead() and combatant_resource is ResEnemyCombatant:
		#playIdle('KO')
	#else:
	playIdle()
	
	#is_

func doAnimation(animation: String, script: GDScript=null, data:Dictionary={}):
	#animator.play("RESET")
	#CLEAN
	if data.has('low_priority') and animator.is_playing():
		return
	if !data.has('bypass_invalid_pause') and (cannotAct() or animation == ''): 
		await get_tree().create_timer(0.25).timeout
		return
	if combatant_resource.hasStatusEffect('Knockback'):
		await get_tree().create_timer(0.25).timeout
		await moveTo(get_parent(),0.12)
		combatant_resource.getStatusEffect('Knockback').removeStatusEffect()
		return
#	if CombatGlobals.getCombatScene().has_node('QTE'):
#		await CombatGlobals.qte_finished
#		await CombatGlobals.getCombatScene().get_node('QTE').tree_exited
	if !animator.get_animation_list().has(animation) and !data.has('no_anim_fallback'): 
		if animator.get_animation_list().has('Cast_Misc'):
			animation = 'Cast_Misc'
		else:
			animation = 'Cast_Melee'
		combatant_resource.stopBreatheTween()
	
	#CLEAN
	if script != null: 
		hit_script = script
		if data.has('target_count'): 
			resizeHitbox(data['target_count'])
		else:
			resizeHitbox(1)
	if animation == 'Cast_Ranged' and data.has('target') and CombatGlobals.inCombat():
		setProjectileTarget(data['target'], data['frame_time'], data['ability'])
	if data.keys().has('anim_speed'):
		animator.play(animation, -1, data['anim_speed'])
	else:
		animator.play(animation, -1)
	await animator.animation_finished
	#CLEAN
	
	if CombatGlobals.inCombat() and CombatGlobals.getCombatScene().has_node('Projectile'): 
		await CombatGlobals.getCombatScene().get_node('Projectile').tree_exited
	#animator.play('RESET')
	if !data.has('skip_pause') or (CombatGlobals.inCombat()):
		await get_tree().create_timer(0.25).timeout
	if !data.has('skip_idle'):
		playIdle()
	hit_script = null

func resizeHitbox(target_count:int):
	var hitbox_size = 32
	hitbox_shape.shape.size.x = hitbox_size * target_count
	hitbox_shape.position.x = (hitbox_size/2) * (target_count+1.75)
	if combatant_resource is ResEnemyCombatant:
		hitbox_shape.position.x *= -1

func cannotAct()-> bool:
	return combatant_resource.isDead(true) #and !combatant_resource.hasStatusEffect('Fading')

func playIdle(new_idle:String='',is_temporary:bool=false):
	if !animator.get_animation_list().has(new_idle) and new_idle != '':
		return
	if new_idle != '':
		idle_animation = new_idle
	
	combatant_resource.resetSprite()
	combatant_resource.startBreatheTween(false)
	if temporary_idle != '' and idle_animation != temporary_idle:
		animator.play(temporary_idle)
		temporary_idle = ''
	else:
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
		hit_script.applyAbilityEffects(self, body, CombatGlobals.getCombatScene().selected_ability)

func _to_string():
	return combatant_resource.name

func _exit_tree():
	if combatant_resource.scale_tween != null and combatant_resource.pos_tween != null:
		combatant_resource.scale_tween.kill()
		combatant_resource.pos_tween.kill()
		combatant_resource.scale_tween = null
		combatant_resource.pos_tween = null
		combatant_resource.resetSprite()
