extends Control
class_name ItemPickupNotifier

@onready var pickup_label_template = $VBoxContainer/PickupLabel
@onready var label_container = $VBoxContainer

func _ready():
	InventoryGlobals.added_item_to_inventory.connect(addPickupLabel)
	InventoryGlobals.removed_item_from_inventory.connect(func(item): if !item is ResStackItem: addPickupLabel(item,-1,true))
	InventoryGlobals.stack_item_changed.connect(func(item,count): if count<0: addPickupLabel(item,count,true))

func addPickupLabel(item:ResItem,count:int,remove_item:bool=false):
	if (item is ResProjectileAmmo and remove_item and !OverworldGlobals.inMenu()): 
		return
	if remove_item and OverworldGlobals.player.current_camp_spot != null:
		return
	if OverworldGlobals.getMenu() is GameMenu:
		return
	
	var pickup_label:RichTextLabel = pickup_label_template.duplicate()
	var tween:Tween = create_tween()
	tween.finished.connect(func(): pickup_label.queue_free())
	
	pickup_label.text = getAddedText(item,count,remove_item)
	pickup_label.modulate = Color.TRANSPARENT
	
	if remove_item:
		pickup_label.get_node('Background').self_modulate=Color.DARK_RED
	
	pickup_label.show()
	
	label_container.add_child(pickup_label)
	tween.tween_property(pickup_label,'modulate', Color.WHITE,0.25)
	tween.tween_interval(2)
	tween.tween_property(pickup_label,'modulate', Color.TRANSPARENT,0.25)

func getAddedText(item:ResItem,count:int,remove_item:bool):
	var base_text="[fill][img]res://images/item_icons/.ICON.[/img][color=TRANSPARENT]a[/color].ITEM.[color=TRANSPARENT]a[/color] +.COUNT.[color=TRANSPARENT]a[/color].TOTALCOUNT."
	base_text=base_text.replace('.ICON.',item.icon.resource_path.get_file())
	base_text=base_text.replace('.ITEM.',item.name.replace(' ', '[color=TRANSPARENT]a[/color]'))
	if remove_item:
		base_text=base_text.replace('+.COUNT.','-'+str(count) if count>0 else str(count))
	else:
		base_text=base_text.replace('.COUNT.',str(count))
	
	base_text=base_text.replace('.TOTALCOUNT.','[color=#FFFFFF80]('+str(InventoryGlobals.getItemCount(item))+')[/color]')
	return base_text
