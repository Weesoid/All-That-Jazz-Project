extends CustomButton
class_name RepairButton

@export var combatant: ResPlayerCombatant
@export var weapon: ResWeapon

@onready var combatant_texture = $Portrait
@onready var resource_texture: ItemComponentIcon = $MarginContainer/HBoxContainer/ItemComponentIcon
@onready var weapon_texture: ItemComponentIcon = $MarginContainer/HBoxContainer/ItemComponentIcon2

func _ready():
	$HoldProgress.modulate=hold_color
	if combatant != null:
		combatant_texture.texture = combatant.rest_sprite
	resource_texture.item = weapon.repair_item
	resource_texture.required = weapon.repair_cost
	weapon_texture.item = weapon
	updateInformation()

func updateInformation():
	var repair_item_label = resource_texture.get_node('CurrentCount')
	disabled = !weapon.canRepair(1)
	if disabled:
		dimButton()
	else:
		undimButton()
	
	resource_texture.update()
	weapon_texture.update(true)
#	weapon_texture.get_node('Durability').text = '%s/%s' % [weapon.durability,weapon.max_durability]
#	if InventoryGlobals.hasItem(weapon.repair_item):
#		repair_item_label.text = str(weapon.repair_item.stack)
#		repair_item_label.show()
#	else:
#		repair_item_label.hide()
#
#	if InventoryGlobals.hasItem(weapon.repair_item,weapon.repair_cost):
#		repair_item_label.modulate = Color.WHITE
#		resource_texture.self_modulate = Color.WHITE
#	else:
#		repair_item_label.modulate = Color.RED
#		resource_texture.self_modulate = Color.RED
#	resource_texture.get_node('RequiredCount').text = 'x'+str(weapon.repair_cost)

func dimButton():
	modulate = Color(Color.DARK_GRAY,0.95)

func undimButton():
	modulate= Color.WHITE

func press_feedback():
	if click_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()
	var scale_tween = create_tween()
	scale_tween.tween_property(weapon_texture,'scale',Vector2(1.25,1.25),0.1).set_ease(Tween.EASE_IN)
	scale_tween.tween_property(weapon_texture,'scale',Vector2(1,1),0.25).set_ease(Tween.EASE_OUT)
