extends Control
class_name CombatInspector

@onready var attributes = $Attributes/VBoxContainer/MarginContainer/AttributeView
@onready var other_attributes = $Attributes/VBoxContainer/MarginContainer/AutoAttributeView
@onready var combatant_name = $Attributes/VBoxContainer/Name/MarginContainer/Label
@onready var strain_label = $Attributes/VBoxContainer/MarginContainer/AttributeView/Strain
@onready var ability_label_container = $Abilities/VBoxContainer/MarginContainer/ScrollContainer/HBoxContainer
@onready var modifier_label_container = $Modifiers/VBoxContainer/MarginContainer/ScrollContainer/HBoxContainer
@onready var round_count_label = $Rounds/MarginContainer/Label
@onready var animator = $AnimationPlayer
var combat_scene: CombatScene
var current_combatant: ResCombatant
#var original_positions = {}

func _ready():
	hide()
	combat_scene = CombatGlobals.getCombatScene()
	combat_scene.round_concluded.connect(updateRound)
#	await get_tree().process_frame
#	for panel in get_children():
#		original_positions[panel] = panel.position

func setCombatant(combatant:ResCombatant):
	clear()
	current_combatant = combatant
	await get_tree().process_frame
	strain_label.hide()
	attributes.setCombatant(combatant)
	other_attributes.setCombatant(combatant)
	combatant_name.text = combatant.name
	for ability in combatant.ability_set:
		ability_label_container.add_child(UIGlobals.createAbilityLabel(ability, combatant))
	for effect in combatant.status_effects:
		modifier_label_container.add_child(UIGlobals.createStatusEffectLabel(effect, combatant))
	for modifier in combatant.getTemporaryModifierKeys():
		modifier_label_container.add_child(UIGlobals.createStatModifierLabel(modifier, combatant))
	if combatant is ResPlayerCombatant:
		for modifier in combatant.getTraitsWithFlag('injury'):
			modifier_label_container.add_child(UIGlobals.createStatModifierLabel(modifier, combatant))
	await get_tree().process_frame
	UIGlobals.setVerticalNeighbors(modifier_label_container)

func showInspector():
	show()
	animator.play("Show")

func hideInspector():
	animator.play_backwards("Show")
	await animator.animation_finished
	hide()
func clear():
	for ability in ability_label_container.get_children():
		ability.queue_free()
	for effect in modifier_label_container.get_children():
		effect.queue_free()

func updateRound():
	round_count_label.text = 'ROUND ' + str(combat_scene.round_count)
