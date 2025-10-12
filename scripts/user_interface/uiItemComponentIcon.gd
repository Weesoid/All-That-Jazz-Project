extends TextureRect
class_name ItemComponentIcon

@export var item: ResItem
@export var required: int
@onready var current_count = $CurrentCount
@onready var required_count = $RequiredCount

func update(is_product:bool=false):
	texture = item.icon
	
	if item is ResWeapon:
		current_count.hide()
		required_count.text = '%s/%s' % [str(item.durability), str(item.max_durability)]
	else:
		required_count.text = 'x'+str(required)
	
	if item is ResStackItem:
		current_count.text = str(item.stack)
	elif item is ResCharm:
		current_count.text = str(InventoryGlobals.getCharms(item).size())
	
	if !is_product and InventoryGlobals.hasItem(item,required,false):
		current_count.modulate = Color.WHITE
		self_modulate = Color.WHITE
	elif !is_product and InventoryGlobals.hasItem(item,1,false):
		current_count.modulate = Color.RED
		self_modulate = Color(Color.WHITE,0.25)
	elif !is_product and !InventoryGlobals.hasItem(item,1,false):
		current_count.modulate = Color.RED
		self_modulate = Color(Color.WHITE,0.25)
		current_count.text = str(0)
	
	if is_product and InventoryGlobals.hasItem(item):
		current_count.show()
	if is_product and item is ResStackItem and item.stack >= item.max_stack:
		current_count.modulate = Color.YELLOW
	elif is_product and item is ResStackItem and item.stack < item.max_stack and InventoryGlobals.hasItem(item):
		current_count.modulate = Color.WHITE
	elif is_product and !InventoryGlobals.hasItem(item,1,false):
		current_count.hide()

func doPopTween():
	var scale_tween = create_tween()
	scale_tween.tween_property(self,'scale',Vector2(1.25,1.25),0.1).set_ease(Tween.EASE_IN)
	scale_tween.tween_property(self,'scale',Vector2(1,1),0.25).set_ease(Tween.EASE_OUT)
