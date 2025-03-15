class_name FilterButton extends Button


signal filter_pressed(filter_name: String)
signal filter_released


func _init(_filter_name, _toggle_mode: bool = true) -> void:
	name = _filter_name
	toggle_mode = _toggle_mode


func _ready() -> void:
	icon = get_theme_icon(name, "EditorIcons")
	focus_mode = Control.FOCUS_NONE
	
	if toggle_mode:
		toggled.connect(_on_toggled)
	else:
		pressed.connect(_on_pressed)


func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		filter_pressed.emit(name)
	else:
		filter_released.emit()


func _on_pressed() -> void:
	filter_pressed.emit(name)
