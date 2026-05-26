extends Control
class_name CharSheet

const SWORD_ICON = "res://images/sprites/icon_combat_item_trans.png"
const SACK_ICON = "res://images/sprites/icon_charm_trans.png"
const SWORD_SHIELD_ICON = preload("res://images/sprites/sword_n_shield.png")
const SHIELD_SWORD_ICON = preload("res://images/sprites/shield_n_sword.png")
const ABILITIES_ICON = preload("res://images/sprites/abilities_icon.png")
const MODIFIERS_ICON = preload("res://images/sprites/modifiers.png")

@onready var modifier_viewer = $Sheet/LeftBeef/AbilitiesViewer/ModifierViewer
@onready var attribute_viewer = $Sheet/Right/VBoxContainer/AttributeViewContainer
@onready var other_attribute_viewer = $Sheet/Right/VBoxContainer/AutoAttributeView
@onready var abilities_container = $Sheet/LeftBeef/AbilitiesViewer/AbilityContainer
@onready var character_view = $Sheet/Center/CharacterPosition/Marker2D
@onready var character_name = $Sheet/Center/Label
@onready var talents = $Talents
@onready var equipment = $MiniInventory
@onready var equip_slot_weapon = $Sheet/Right/VBoxContainer/Equipment/Weapon
#@onready var weapon_durability_label = $Sheet/Right/VBoxContainer/Equipment/Weapon/Label
@onready var equip_slot_a = $Sheet/Right/VBoxContainer/Equipment/SlotA
@onready var equip_slot_b =$Sheet/Right/VBoxContainer/Equipment/SlotB
@onready var equip_slot_c = $Sheet/Right/VBoxContainer/Equipment/SlotC
@onready var press_cooldown = $Timer
@onready var toggle_stats_button = $Sheet/Right/HBoxContainer2/ToggleStats
@onready var toggle_ability_modifier_button = $Sheet/LeftBeef/HBoxContainer/ToggleAbilityModifiers
@onready var ability_view = $Sheet/LeftBeef/AbilitiesViewer
#@onready var modifier_view = $Sheet/LeftBeef/ModifierViewer
@onready var stat_point_count = $Sheet/LeftBeef/AbilitiesViewer/HBoxContainer/ShowTalents/Label

var submenu_positions = {}
var selected_equip_slot:int=0
var loaded_characters = []
var prev_pos: Vector2 

signal combatant_switched

func _ready():
	await get_tree().process_frame
	submenu_positions[talents] = talents.position
	submenu_positions[equipment] = equipment.position
	submenu_positions['talents-offset'] = Vector2(-128,0)
	submenu_positions['equipment-offset'] = Vector2(0,64)
#	equip_slot_weapon.item_received.connect(replaceEquippable)
#	equip_slot_a.item_received.connect(replaceEquippable)
#	equip_slot_b.item_received.connect(replaceEquippable)
#	equip_slot_c.item_received.connect(replaceEquippable)
	talents.talent_interacted.connect(updateStatPoints)
	combatant_switched.connect(hideSubmenus.unbind(1))

func hideSubmenus():
	animateSubmenu(false, equipment,submenu_positions['equipment-offset'])
	animateSubmenu(false, talents,submenu_positions['talents-offset'])

#func replaceEquippable(item_equipped):
#	if item_replaced != null:
#		equipment.addButton(item_replaced)
#	if equipment.item_button_map.is_empty():
#		animateSubmenu(false,equipment,submenu_positions['equipment-offset'])

func setCombatant(combatant: ResPlayerCombatant):
	combatant_switched.emit(combatant)
	abilities_container.clear()
	modifier_viewer.loadModifiers(combatant)
	attribute_viewer.setCombatant(combatant)
	other_attribute_viewer.setCombatant(combatant,true)
	abilities_container.loadAbilities(combatant)
	talents.loadTalents(combatant)
	updateCharacterView(combatant)
	setEquipSlots(combatant)
	updateStatPoints(combatant)

func setEquipSlots(combatant:ResPlayerCombatant):
	equip_slot_weapon.setCombatant(combatant)
	equip_slot_a.setCombatant(combatant)
	equip_slot_b.setCombatant(combatant)
	equip_slot_c.setCombatant(combatant)

func updateStatPoints(combatant:ResCombatant):
	stat_point_count.text = str(combatant.stat_points)

# TODO Load all character views and store them for toggle
func updateCharacterView(member: ResPlayerCombatant):
	if character_view.has_node('CharacterBody2D'):
		var last_member = character_view.get_node('CharacterBody2D')
		character_view.remove_child(last_member)
		last_member.queue_free()
	
	var character_scene = member.getScenePreview()
	character_name.text = member.name.to_upper()
	if character_scene:
		character_scene.scale = Vector2(2,2)
		character_view.add_child(character_scene)
		character_scene.collision.disabled = true
		character_scene.combatant_resource.getAnimator().play('RESET')
		await character_scene.combatant_resource.getAnimator().animation_finished
		character_scene.playIdle()


func _on_show_talents_pressed():
	animateSubmenu(!talents.visible, talents, submenu_positions['talents-offset'])

func _on_slot_a_pressed():
	selected_equip_slot=0

func _on_slot_b_pressed():
	selected_equip_slot=1

func _on_slot_c_pressed():
	selected_equip_slot=2

func equipmentButtonPressed():
	if !press_cooldown.is_stopped():
		return
	var all_equippables = InventoryGlobals.inventory.filter(func(item): return item is ResEquippable)
	if all_equippables.is_empty():
		CombatGlobals.spawnIndicator(get_global_mouse_position(), 'No equipment!')
		return
	
	press_cooldown.start()
	if equipment.visible:
		equipment.reset()
	else:
		loadEquipment()
	
	animateSubmenu(!equipment.visible, equipment, submenu_positions['equipment-offset'])
	if equipment.visible:
		await get_tree().process_frame
		equipment.focusFirstFilled()
	
func loadEquipment():
	equipment.reset()
	equipment.showItems(func(item): return item is ResEquippable)
#	OverworldGlobals.addMiniInventoryActions(
#		equipment,
#		0,
#		func(): pass,
#		func(item): return item is ResEquippable #and !viewed_combatant.hasCharm(item)
#		)

func animateSubmenu(set_visible:bool, submenu:Control, offscreen_offset:Vector2):
	var tween = create_tween().set_parallel()
	var offscreen_pos = submenu_positions[submenu]+offscreen_offset
	if set_visible:
		tween.set_ease(Tween.EASE_IN)
		submenu.modulate = Color.TRANSPARENT
		submenu.position = offscreen_pos
		submenu.show()
		tween.tween_property(submenu,'modulate',Color.WHITE,0.2)
		tween.tween_property(submenu,'position',submenu_positions[submenu],0.25)
	else:
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(submenu,'modulate',Color.TRANSPARENT,0.2)
		tween.tween_property(submenu,'position',offscreen_pos,0.25)
		await tween.finished
		submenu.hide()


func _on_toggle_stats_pressed():
	attribute_viewer.visible = !attribute_viewer.visible
	other_attribute_viewer.visible = !other_attribute_viewer.visible
	
	if attribute_viewer.visible:
		toggle_stats_button.setTexture(SHIELD_SWORD_ICON)
		toggle_stats_button.getTexture().flip_h = false
	else:
		toggle_stats_button.setTexture(SWORD_SHIELD_ICON)
		toggle_stats_button.getTexture().flip_h = true


func _on_toggle_ability_modifiers_pressed():
	if abilities_container.visible:
		abilities_container.hide()
		modifier_viewer.show()
	else:
		abilities_container.show()
		modifier_viewer.hide()
	
	if ability_view.visible:
		toggle_ability_modifier_button.setTexture(ABILITIES_ICON)
	else:
		toggle_ability_modifier_button.setTexture(MODIFIERS_ICON)


func _on_toggle_equipment_pressed():
	pass # Replace with function body.
