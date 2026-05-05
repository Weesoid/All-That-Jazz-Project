extends CustomButton
class_name CustomDragDropButton

func _get_drag_data(at_position):
	return self

func _can_drop_data(_at_position, data):
	return data is CustomDragDropButton

func _drop_data(_at_position, data):
	print('received ', data)

func getPreview():
	var icon_texture = TextureRect.new()
	var preview = Control.new()
	icon_texture.texture = icon
	icon_texture.expand_mode=1
	icon_texture.size = icon.get_size()*2
	#icon_texture.pivot_offset = icon_texture.size/2
	preview.add_child(icon_texture)
	return preview
