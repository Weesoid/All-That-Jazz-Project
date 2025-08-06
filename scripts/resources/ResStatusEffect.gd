extends Resource
class_name ResStatusEffect

enum EffectType {
	STANDARD,
	ON_HIT,
	DYNAMIC
}
enum RemoveType {
	HIT,
	MISSED,
	GET_HIT,
	GET_HEAL,
	GET_TARGETED,
	GET_STATUSED
}
enum RemoveStyle {
	REMOVE,
	TICK_DOWN
}

## NOTE: Always name status effects with the following convention: File-GuardBreak.tres;Name-Guard Break
@export var auto_name:bool=true
@export var name: String
@export_multiline var description: String
@export var basic_effects: Array[ResBasicEffect]
@export var status_script: GDScript = preload("res://scripts/combat/status_effects/scsBasicStatus.gd")
@export var packed_scene: PackedScene
@export var effect_type: EffectType
@export var remove_when: Array[RemoveType]
@export var remove_style: RemoveStyle
@export var texture: Texture = preload("res://images/sprites/unknown_icon.png")
@export var max_duration: int = 1
@export var extend_duration: int = 1
@export var apply_extend_duration:  bool = false
@export var max_rank: int
@export var tick_on_apply: bool = true
## Do ticks even though it's not the afflicted combatant's turn.
@export var tick_any_turn: bool
@export var do_ticks: bool = true
@export var resistable: bool = true
@export var permanent: bool = false
@export var lingers: bool = false
@export var persist_on_dead: bool = false
@export var sounds: Dictionary = {'apply':'', 'expire':''}

var apply_once = true
var duration
var current_rank = 1
var afflicted_combatant: ResCombatant
var attached_data
var status_visuals
var icon: TextureRect

func initializeStatus():
	icon = TextureRect.new()
	icon.texture = texture
	
	if packed_scene != null:
		status_visuals = packed_scene.instantiate()
		animateStatusEffect()
	
	if effect_type == EffectType.ON_HIT:
		CombatGlobals.received_combatant_value.connect(onHitTick)
	elif effect_type == EffectType.DYNAMIC:
		status_visuals.status_effect = self
	
	if !apply_extend_duration:
		duration = max_duration
	else:
		duration = extend_duration

func onHitTick(combatant, caster, received_value):
	if combatant == afflicted_combatant:
		status_script.applyHitEffects(afflicted_combatant, caster, received_value, self)

func removeStatusEffect():
	if effect_type == EffectType.ON_HIT:
		CombatGlobals.received_combatant_value.disconnect(onHitTick)
	
	if sounds['expire'] != '':
		OverworldGlobals.playSound(sounds['expire'])
	if status_script != null:
		status_script.endEffects(afflicted_combatant, self)
	if status_visuals != null:
		status_visuals.queue_free()
	if (CombatGlobals.randomRoll(0.15+afflicted_combatant.stat_values['resist']) or afflicted_combatant.isDead()) and afflicted_combatant is ResPlayerCombatant and lingers and !persist_on_dead and resistable:
		afflicted_combatant.lingering_effects.erase(name)
		CombatGlobals.manual_call_indicator.emit(afflicted_combatant, 'Cured %s!' % name, 'Heal')
	elif afflicted_combatant is ResPlayerCombatant and lingers:
		CombatGlobals.manual_call_indicator.emit(afflicted_combatant, '%s Supressed!' % name, 'Flunk')
	
	if is_instance_valid(icon):
		icon.queue_free()
	afflicted_combatant.status_effects.erase(self)

func tick(update_duration=true, override_permanent=false, apply_effects=true):
	if (!permanent and update_duration) or override_permanent: 
		duration -= 1
	
	if status_script != null and do_ticks and apply_effects:
		status_script.applyEffects(afflicted_combatant, self)
	
	apply_once = false
	if ((duration <= 0 and ((permanent and !remove_when.is_empty()) or !permanent)) or (afflicted_combatant.isDead() and !persist_on_dead)) and status_script != null:
		#print('Removing ', self)
		removeStatusEffect()
# ['Knock Out', 'Fading', 'Deathmark'].has(name)

func animateStatusEffect():
	if status_visuals == null:
		return
	
	status_visuals.global_position = Vector2(0, 0)
	afflicted_combatant.combatant_scene.add_child(status_visuals)
	if status_visuals.has_node('AnimationPlayer'):
		status_visuals.get_node('AnimationPlayer').play('Show')
	if status_visuals is DynamicStatusEffect:
		status_visuals.status_effect = self
		if afflicted_combatant is ResEnemyCombatant and !afflicted_combatant.combatant_scene is PlayerCombatantScene:
			status_visuals.rotation_degrees = -180

func getDescription():
	var out_description = description
	if max_rank > 1: out_description += ' (%s/%s)' % [current_rank, max_rank]
	return out_description

func _to_string():
	return name

#func getFilename():
#	return resource_path.get_file().replace('.tres','')
