@tool
class_name NodeFilteringUtilityClass


## Returns all children of given type.
## The returned Array is untyped, so it has to be assigned to a typed array later.
static func get_children_of_type(parent: Node, type: Variant, recursive: bool = true) -> Array:
	assert(parent, "parent is null")
	var array: Array
	for child: Node in parent.get_children():
		if is_instance_of(child, type):
			array.append(child)
		if recursive:
			array.append_array(get_children_of_type(child, type, recursive))
	return array


## Returns the first child of given type, will ignore the other children.
## The returned Node is untyped, so it has to be casted to a type later.
static func get_child_of_type(parent: Node, type: Variant) -> Node:
	assert(parent, "parent is null")
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if is_instance_of(child, type):
			return child
	return null


static func get_children_types(parent: Node, recursive: bool = true, owned: bool = false) -> Array[String]:
	assert(parent, "parent is null")
	var array: Array[String]
	for child: Node in parent.get_children():
		if owned and !child.owner:
			continue
		if not array.has(child.get_class()):
			array.append(child.get_class())
		if recursive and (parent.is_editable_instance(child) and child.scene_file_path != "" or child.scene_file_path == ""):
			array.append_array(get_children_types(child, recursive, owned))
	var dict: Dictionary[String, int]
	for element in array:
		dict[element] = 0
	return dict.keys()


static func find_editable_children(parent: Node, type: String, recursive: bool = true, owned: bool = false) -> Array:
	assert(parent, "parent is null")
	var array: Array
	for child: Node in parent.get_children():
		if owned and !child.owner:
			continue
		if type.is_empty() or child.is_class(type):
			array.append(child)
		if recursive and (parent.is_editable_instance(child) and child.scene_file_path != "" or child.scene_file_path == ""):
			array.append_array(find_editable_children(child, type, recursive, owned))
	return array
