extends CustomDragDropButton
class_name ItemSlot

@export var empty_icon:Texture = preload("res://images/sprites/icon_charm_trans.png")
@export var drop_sound: AudioStream = preload("res://audio/sounds/421461__jaszunio15__click_46.ogg")
@export var pickup_sound: AudioStream = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")
@onready var durability_bar = $Durability
var item: ResItem
signal item_received(received_item, last_item)
signal item_dragged(item)
signal item_replaced(item)

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

func drop_feedback():
	OverworldGlobals.playSound(drop_sound.resource_path)
	#playSound(drop_sound)

func pick_up_feedback():
	playSound(pickup_sound)

