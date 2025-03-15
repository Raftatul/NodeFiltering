@tool
class_name NodeFiltering extends EditorPlugin


const NODE_FILTERING_PANEL = preload("node_filtering_panel.tscn")

var panel: Control


func _ready() -> void:
	panel = NODE_FILTERING_PANEL.instantiate()
	panel.plugin = self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, panel)


func _exit_tree() -> void:
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
