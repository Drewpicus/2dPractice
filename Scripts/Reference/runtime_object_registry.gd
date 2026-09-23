extends RefCounted
class_name RuntimeObjectRegistry

static var _objects: Dictionary[String, WeakRef] = {}


static func generate_unique_id() -> String:
	var new_id := RuntimeID.generate()

	while has(new_id):
		new_id = RuntimeID.generate()

	return new_id


static func register(object: Object, instance_id: String) -> bool:
	if not object:
		return false

	if instance_id.is_empty():
		push_error("Cannot register a runtime object with an empty instance ID.")
		return false

	var existing := get_object(instance_id)

	if existing:
		if existing == object:
			return true

		push_error("Runtime instance ID is already registered: %s" % instance_id)
		return false

	_objects[instance_id] = weakref(object)
	return true


static func unregister(instance_id: String, object: Object = null) -> bool:
	if not _objects.has(instance_id):
		return false

	var existing := get_object(instance_id)

	if object and existing != object:
		return false

	_objects.erase(instance_id)
	return true


static func reassign(object: Object, old_id: String, new_id: String) -> bool:
	if not object:
		return false

	if new_id.is_empty():
		push_error("Cannot assign an empty runtime instance ID.")
		return false

	var existing := get_object(new_id)

	if existing and existing != object:
		push_error("Runtime instance ID is already registered: %s" % new_id)
		return false

	if _objects.has(old_id):
		var old_object := get_object(old_id)

		if old_object == object:
			_objects.erase(old_id)

	_objects[new_id] = weakref(object)
	return true


static func get_object(instance_id: String) -> Object:
	if not _objects.has(instance_id):
		return null

	var obj_reference = _objects[instance_id]

	if not obj_reference:
		_objects.erase(instance_id)
		return null

	var object = obj_reference.get_ref()

	if not object:
		_objects.erase(instance_id)
		return null

	return object


static func get_entity(instance_id: String) -> Entity:
	return get_object(instance_id) as Entity


static func get_item(instance_id: String) -> Item:
	return get_object(instance_id) as Item


static func has(instance_id: String) -> bool:
	return get_object(instance_id) != null


static func clear() -> void:
	_objects.clear()
