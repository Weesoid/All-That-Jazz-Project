extends CustomDragDropButton
class_name ItemSlot

@export var empty_icon:Texture = preload("res://images/sprites/icon_charm_trans.png")
@export var drop_sound: AudioStream = preload("res://audio/sounds/421461__jaszunio15__click_46.ogg")
@export var pickup_sound: AudioStream = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")
@export var item_whitelist:Array[ResItem]=[]
@export var drop_disabled:bool=false
var can_drop_function:Callable=func(): return true

@onready var durability_bar = $Durability
var item: ResItem
signal item_received(item)
signal item_dragged(item)
signal item_replaced(previous_item)

func ready():
	icon = empty_icon
	description_offset = Vector2(0,-32)

func setItem(data: ResItem):
	durability_bar.hide()
	if item != null:
		item_replaced.emit(item)
	item = data
	if data != null:
		icon = data.icon
		description_text = data.getInformation()
	else:
		icon = empty_icon
		description_text = ''
	if data != null and item.isRepairable():
		durability_bar.setItem(item)
		durability_bar.show()
	if item != null:
		item_received.emit(data)

func _can_drop_data(_at_position, data):
	print(can_drop_function.call())
	return !item_whitelist.is_empty() and item_whitelist.has(data) and !disabled and can_drop_function.call()

func _drop_data(_at_position, data):
	setItem(data)
	drop_feedback()

func drop_feedback():
	OverworldGlobals.playSound(drop_sound.resource_path)

func pick_up_feedback():
	playSound(pickup_sound)

func _force_drop():
	pass
	#if get_viewport().gui_is_dragging():
	#	SettingsGlobals.click()


#func _on_pressed_force_drag():
#	print('dragqueen')
#	force_drag(item, getPreview())
