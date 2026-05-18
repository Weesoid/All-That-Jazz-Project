@tool
extends Resource
class_name ResStatKeyValue


#func _validate_property(property: Dictionary) -> void:
#	if property.name == "items":
#		# Load the item db
#		var item_db = preload("res://item_db.tres")
#		# Join the items array by comma
#		var items = ",".join(item_db.items)
#		# Create the hint string <type>/<hint>:<hint_string>
#		property.hint_string = "%d/%d:%s" % [TYPE_INT, PROPERTY_HINT_ENUM, items]
