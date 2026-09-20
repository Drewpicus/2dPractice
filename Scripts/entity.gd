extends CharacterBody2D
class_name Entity

@onready var collision = $CollisionShape2D
@onready var components_folder = $Components

var components: Array

func _ready() -> void:
	var health_component := get_component(&"health") as HealthComponent
	if health_component:
		health_component.health_depleted.connect(die)

func die() -> void:
	var remains_component = get_component(&"remains")
	if remains_component:
		remains_component.spawn_remains()
	queue_free()

##Add a component to the component folder, based on name, e.g. &"health"
##Parameters are a dict with the keys being variable names and the values being values
func add_component(component:StringName,parameters:Dictionary={}) -> Node:
	if not components_folder:
		components_folder = get_node_or_null("Components")

	if component.is_empty():
		return
	
	if has_component(component):
		return
	
	var component_scene: PackedScene = EntityComponentRegistry.get_component_scene(component)
	if component_scene == null:
		return
	
	var new_component: Node = component_scene.instantiate()
	
	if not parameters.is_empty():
		for key in parameters.keys():
			if key in new_component:
				new_component.set(key,parameters[key])
	
	components_folder.add_child(new_component)
	return new_component

##Remove a component from the component folder, based on name, e.g. &"health"
func remove_component(component:StringName) -> void:
	if not components_folder:
		components_folder = get_node_or_null("Components")
	
	if component.is_empty():
		return
	components_folder = get_node_or_null("Components")
	
	if components_folder == null:
		return
	
	var component_name: String = EntityComponentRegistry.get_component_name(component)
	if component_name.is_empty():
		return
	
	for child in components_folder.get_children():
		if child.name == component_name:
			child.queue_free()
			return

##Returns true if the Entity has the given component
func has_component(component:StringName) -> bool:
	return get_component(component) != null

##Returns Component Node of a given name if an Entity has it, otherwise returns null
func get_component(component:StringName) -> Node:
	var component_name: String = EntityComponentRegistry.get_component_name(component)
	if not components_folder:
		components_folder = get_node_or_null("Components")
	return components_folder.get_node_or_null(component_name)

##Sets a collision shape to match with the Entity's
func apply_entity_collision_to(target: CollisionShape2D) -> void:
	if target.shape != null:
		return

	if collision == null:
		collision = $CollisionShape2D

	if collision.shape == null:
		return

	target.shape = collision.shape.duplicate()
	target.position = collision.position
	target.rotation = collision.rotation
	target.scale = collision.scale

##When run on a component, returns its root Entity.
##Also works on sprites, hitboxes, or anything under an Entity.
static func find_entity(node:Node) -> Entity:
	while node != null:
		if node is Entity:
			return node
		node = node.get_parent()
	return null
