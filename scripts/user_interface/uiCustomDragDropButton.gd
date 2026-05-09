extends CustomButton
class_name CustomDragDropButton

func getPreview():
	var icon_texture = TextureRect.new()
	var preview = Control.new()
	icon_texture.texture = icon
	icon_texture.expand_mode=1
	icon_texture.size = icon.get_size()*2
	preview.add_child(icon_texture)
	preview.z_index=4000
	return preview
