extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel

func set_item(item_data: Dictionary) -> void:
	if item_data.texture:
		item_icon.texture = item_data.texture
		item_icon.show()
	else:
		item_icon.hide()
	
	if item_data.quantity > 1:
		quantity_label.text = str(item_data.quantity)
		quantity_label.show()
	else:
		quantity_label.hide() 