@tool
extends Control


const PREFIX: String = "tt:"
const FILTER_EDIT_PATH: String = "/root/0/@Panel@14/@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockVSplitLeftR/DockSlotLeftUR/Scene/@HBoxContainer@5043/@LineEdit@5044"

const FILTERS_PATH = "res://addons/node_filtering/filters.txt"

var plugin: NodeFiltering

var edited_scene_root: Node
var edit: LineEdit

var type_in_tree: Array[String]
var buttons: Dictionary[String, BaseButton]

var current_tab: int = -1

@onready var tab_container: TabContainer = %TabContainer


func _ready() -> void:
	edit = NodeFilteringUtilityClass.get_children_of_type(EditorInterface.get_base_control(), LineEdit)[0]
	plugin.scene_changed.connect(_on_tree_loaded)
	plugin.scene_changed.connect(_on_edited_scene_changed)
	
	if EditorInterface.get_edited_scene_root():
		_on_tree_loaded(EditorInterface.get_edited_scene_root())


func _create_buttons(filters: Dictionary, container: Control) -> void:
	for key in filters:
		if !filters[key]:
			continue
		var button: FilterButton = FilterButton.new(key)
		button.filter_pressed.connect(_on_filter_pressed)
		button.filter_released.connect(_on_filter_released)
		container.add_child(button)
		buttons[key] = button


func _generate_tab(tab_name: String, tab_data: Dictionary) -> void:
	var tab: VBoxContainer = VBoxContainer.new()
	
	tab_container.add_child(tab)
	tab.name = tab_name
	
	for key in tab_data:
		var filters_container: HFlowContainer = HFlowContainer.new()
		var label: Label = Label.new()
		
		label.text = key
		
		tab.add_child(label)
		tab.add_child(filters_container)
		
		_create_buttons(tab_data[key], filters_container)


func _generate_filters() -> void:
	buttons.clear()
	
	current_tab = tab_container.current_tab
	
	for i in tab_container.get_child_count():
		tab_container.get_child(0).free()
	
	var file: FileAccess = FileAccess.open(FILTERS_PATH, FileAccess.READ)
	var json: JSON = JSON.new()
	var data: Dictionary = json.parse_string(file.get_as_text())
	
	for key: String in data:
		if key.contains("Example"):
			continue
		_generate_tab(key, data[key])
	
	tab_container.current_tab = min(current_tab, tab_container.get_tab_count() - 1)
	
	_update_buttons_states()


func _on_tree_loaded(scene_root: Node) -> void:
	if plugin.scene_changed.is_connected(_on_tree_loaded):
		plugin.scene_changed.disconnect(_on_tree_loaded)
	edited_scene_root = scene_root
	type_in_tree = NodeFilteringUtilityClass.get_children_types(edited_scene_root)
	
	_connect_signals(edited_scene_root)
	
	_generate_filters()


func _connect_signals(tree_root: Node) -> void:
	tree_root.child_entered_tree.connect(_on_child_entered_tree)
	tree_root.child_exiting_tree.connect(_on_child_exiting_tree)


func _disconnect_signals(tree_root: Node) -> void:
	tree_root.child_entered_tree.disconnect(_on_child_entered_tree)
	tree_root.child_exiting_tree.disconnect(_on_child_exiting_tree)


func _on_edited_scene_changed(scene_root: Node) -> void:
	var new_edited_scene_root = scene_root
	if !new_edited_scene_root:
		return
	
	if edited_scene_root:
		_disconnect_signals(edited_scene_root)
	edited_scene_root = scene_root
	_connect_signals(edited_scene_root)
	
	type_in_tree = NodeFilteringUtilityClass.get_children_types(edited_scene_root)
	_update_buttons_states()


func _update_buttons_states() -> void:
	for key in buttons.keys():
		buttons[key].disabled = !type_in_tree.has(key)


func _on_filter_pressed(filter_name: String) -> void:
	for key in buttons:
		if key != filter_name:
			buttons[key].button_pressed = false

	edit.text = PREFIX + filter_name
	edit.delete_text(0, 1)


func _on_filter_released() -> void:
	edit.text = "t"
	edit.delete_text(0, 1)


func _on_clear_pressed() -> void:
	_on_filter_released()
	
	for key in buttons:
		buttons[key].button_pressed = false


func _on_child_entered_tree(node: Node) -> void:
	if !buttons.has(node.get_class()):
		#printerr(node.get_class(), " is not implemented in filters")
		return
	
	var remaining_node_count: int = NodeFilteringUtilityClass.find_editable_children(edited_scene_root, node.get_class()).size()
	if remaining_node_count > 0:
		buttons[node.get_class()].disabled = false


func _on_child_exiting_tree(node: Node) -> void:
	if !buttons.has(node.get_class()):
		#printerr(node.get_class(), " is not implemented in filters")
		return
	
	var similar_type_nodes: Array = NodeFilteringUtilityClass.find_editable_children(edited_scene_root, node.get_class())
	var remaining_node_count: int = similar_type_nodes.size()
	if remaining_node_count == 1 and similar_type_nodes.has(node):
		buttons[node.get_class()].disabled = true


func _on_refresh_btn_pressed() -> void:
	_generate_filters()
