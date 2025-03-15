@tool
extends Control


const PREFIX: String = "tt:"
const FILTER_EDIT_PATH: String = "/root/@EditorNode@21269/@Panel@14/@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockVSplitLeftR/DockSlotLeftUR/Scene/@HBoxContainer@5043/@LineEdit@5044"

const FILTERS_PATH = "res://addons/node_filtering/filters.txt"

var plugin: NodeFiltering

var edited_scene_root: Node
var edit: LineEdit

var type_in_tree: Array[String]
var buttons: Dictionary[String, BaseButton]

@onready var main_container: Control = %MainContainer

#3D
@onready var _3d_lights_cont: Control = %"3D".get_node("Lights")
@onready var _3d_physics_cont: Control = %"3D".get_node("Physics")
@onready var _3d_misc_cont: Control = %"3D".get_node("Misc")

#2D
@onready var _2d_lights_cont: Control = %"2D".get_node("Lights")
@onready var _2d_physics_cont: Control = %"2D".get_node("Physics")
@onready var _2d_misc_cont: Control = %"2D".get_node("Misc")

#Control
@onready var _control_container_cont: Control = %Control.get_node("Container")
@onready var _control_element_cont: Control = %Control.get_node("Element")
@onready var _control_visual_cont: Control = %Control.get_node("Visual")


func _ready() -> void:
	edit = EditorInterface.get_base_control().get_node(FILTER_EDIT_PATH)
	plugin.scene_changed.connect(_on_tree_loaded)
	plugin.scene_changed.connect(_on_edited_scene_changed)
	
	if EditorInterface.get_edited_scene_root():
		_on_tree_loaded(EditorInterface.get_edited_scene_root())
	#print(EditorInterface.get_open_scenes())
	#EditorInterface.get_edited_scene_root().get_parent().child_entered_tree.connect(_on_tree_loaded)


func _on_tree_loaded(scene_root: Node) -> void:
	if plugin.scene_changed.is_connected(_on_tree_loaded):
		plugin.scene_changed.disconnect(_on_tree_loaded)
	edited_scene_root = scene_root
	type_in_tree = NodeFilteringUtilityClass.get_children_types(edited_scene_root)
	
	_connect_signals(edited_scene_root)
	
	var file: FileAccess = FileAccess.open(FILTERS_PATH, FileAccess.READ)
	var json: JSON = JSON.new()
	var data: Dictionary = json.parse_string(file.get_as_text())
	
	#3D
	_create_buttons(data["3D"]["Visuals"], _3d_lights_cont)
	_create_buttons(data["3D"]["Physics"], _3d_physics_cont)
	_create_buttons(data["3D"]["Misc"], _3d_misc_cont)
	
	#2D
	_create_buttons(data["2D"]["Visuals"], _2d_lights_cont)
	_create_buttons(data["2D"]["Physics"], _2d_physics_cont)
	_create_buttons(data["2D"]["Misc"], _2d_misc_cont)
	
	#Control
	_create_buttons(data["Control"]["Containers"], _control_container_cont)
	_create_buttons(data["Control"]["Elements"], _control_element_cont)
	_create_buttons(data["Control"]["Visuals"], _control_visual_cont)
	
	_update_buttons_states()


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


func _create_buttons(filters: Dictionary, container: Control) -> void:
	for key in filters:
		if !filters[key]:
			continue
		var button: FilterButton = FilterButton.new(key)
		button.filter_pressed.connect(_on_filter_pressed)
		button.filter_released.connect(_on_filter_released)
		container.add_child(button)
		buttons[key] = button
	


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
