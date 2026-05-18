extends CustomButton
class_name CustomDragDropButton

func getPreview():
	var icon_texture = TextureRect.new()
	var preview = Control.new()
	icon_texture.texture = icon
	icon_texture.expand_mode=1
	icon_texture.size = icon.get_size()*2
	preview.add_child(icon_texture)
	#icon_texture.position -= preview.size/2
	preview.z_index=4000
	return preview

func _force_drag():
	pass # Replace with function body.


func _force_drop():
	pass # Replace with function body.
