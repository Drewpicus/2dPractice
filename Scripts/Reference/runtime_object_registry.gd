##A derived registry that holds the IDs of all instances of objects in the game. This list is
##not saved, but built as objects are loaded into the game.
extends RefCounted
class_name RuntimeObjectRegistry

##A weakly-referenced list of all objects in the game by their [code]instance_id[/code].
##The weak reference lets objects be deleted and freed from memory even if they
##still exist within this list.
static var _objects: Dictionary[String, WeakRef] = {}

##Returns a UUID as a [String]
static func generate_unique_id() -> String:
	var new_id := RuntimeID.generate()

	while has(new_id):
		new_id = RuntimeID.generate()

	return new_id

##Registers an [param object] under [param instance_id] in the [RuntimeObjectRegistry].
##Returns if the registration was a success or not.
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

##Removes the reference to an object from the [RuntimeObjectRegistry] based on its [param instance_id].
##The [param object] parameter can be a double-check. Returns true if the object was removed.
static func unregister(instance_id: String, object: Object = null) -> bool:
	if not _objects.has(instance_id):
		return false

	var existing := get_object(instance_id)

	if object and existing != object:
		return false

	_objects.erase(instance_id)
	return true

##Changes the ID of an [param object] from its [param old_id] to its [param new_id]. Returns true upon success.
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

##Almost the same as [member _objects.instance_id] except with checks and cleanup if it finds an old reference.
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

##Returns the [Entity] registered under an [param instance_id]
static func get_entity(instance_id: String) -> Entity:
	return get_object(instance_id) as Entity

##Returns the [Item] registered under an [param instance_id]
static func get_item(instance_id: String) -> Item:
	return get_object(instance_id) as Item

##True if the [param instance_id] refers to a registerd object
static func has(instance_id: String) -> bool:
	return get_object(instance_id) != null

##Clears the entire [RuntimeObjectRegistry]
static func clear() -> void:
	_objects.clear()
