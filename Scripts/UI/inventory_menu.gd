extends PanelContainer
class_name InventoryMenu


var _viewer: Entity
var _owner: Entity

var _inventory: InventoryComponent
var _viewer_equipment: EquipmentComponent

var _selected_item: Item
var _selection_mode: bool = false

@onready var _title: Label = $VBoxContainer/Title
@onready var _item_list: ItemList = $VBoxContainer/ItemList
@onready var _actions: HBoxContainer = $VBoxContainer/Actions
@onready var _close_button: Button = $VBoxContainer/Close


signal item_chosen(item: Item)
signal item_selection_cancelled

func _ready() -> void:
	hide()

	_item_list.item_selected.connect(_on_item_selected)
	_close_button.pressed.connect(_on_close_pressed)


func show_inventory(viewer: Entity, inv_owner: Entity, selection_mode: bool = false) -> void:
	_disconnect_sources()

	_selection_mode = selection_mode

	_viewer = viewer
	_owner = inv_owner

	_inventory = inv_owner.get_component(&"base:inventory") as InventoryComponent

	if not _inventory:
		return

	_viewer_equipment = viewer.get_component(&"base:equipment") as EquipmentComponent

	if not _inventory.items_updated.is_connected(_rebuild_items):
		_inventory.items_updated.connect(_rebuild_items)

	if _viewer_equipment:
		if not _viewer_equipment.equipment_updated.is_connected(_rebuild_actions):
			_viewer_equipment.equipment_updated.connect(_rebuild_actions)

	_title.text = "%s Inventory" % inv_owner.entity_name

	_selected_item = null

	_rebuild_items()
	show()


func close_inventory() -> void:
	_disconnect_sources()

	_selection_mode = false
	_selected_item = null
	_inventory = null
	_viewer_equipment = null
	_viewer = null
	_owner = null

	hide()


func _disconnect_sources() -> void:
	if is_instance_valid(_inventory):
		if _inventory.items_updated.is_connected(_rebuild_items):
			_inventory.items_updated.disconnect(_rebuild_items)

	if is_instance_valid(_viewer_equipment):
		if _viewer_equipment.equipment_updated.is_connected(_rebuild_actions):
			_viewer_equipment.equipment_updated.disconnect(_rebuild_actions)


func _rebuild_items() -> void:
	var previous_selection := _selected_item

	_item_list.clear()

	var selected_index := -1

	for item in _inventory.items:
		if not item:
			continue

		var display_name := item.item_name

		if display_name.is_empty() and item.definition:
			display_name = item.definition.item_name

		if display_name.is_empty():
			display_name = "Unnamed Item"

		var display_sprite := item.sprite

		if not display_sprite and item.definition:
			display_sprite = item.definition.sprite

		var index := _item_list.add_item(display_name, display_sprite)

		_item_list.set_item_metadata(index, item)

		if item == previous_selection:
			selected_index = index

	if selected_index >= 0:
		_item_list.select(selected_index)
		_selected_item = _item_list.get_item_metadata(selected_index) as Item
	else:
		_selected_item = null

	_rebuild_actions()


func _on_item_selected(index: int) -> void:
	_selected_item = _item_list.get_item_metadata(index) as Item
	_rebuild_actions()


func _rebuild_actions() -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()

	if not _selected_item:
		return

	if _selection_mode:
		_add_action_button(
			"Select",
			_choose_selected
		)
		return

	if (_owner != _viewer) and _viewer.has_component(&"base:inventory"):
		_add_action_button(
			"Take",
			_take_selected
		)
		return

	if _owner == _viewer:
		_add_action_button(
			"Drop",
			_drop_selected
		)

	var consumable := _selected_item.get_component(&"base:consumable") as ConsumableItemComponent

	if (consumable and consumable.can_consume(_viewer)):
		_add_action_button("Consume", _consume_selected)

	if not _viewer_equipment:
		return

	var equippable := _selected_item.get_component(&"base:equippable") as EquippableItemComponent

	if not equippable:
		return

	for slot in equippable.slots:
		if slot not in _viewer_equipment.slots:
			continue

		if _viewer_equipment.get_equipment(slot) == _selected_item:
			_add_action_button(
				"Unequip %s" % String(slot).capitalize(),
				_unequip_slot.bind(slot)
			)
		else:
			_add_action_button(
				"Equip %s" % String(slot).capitalize(),
				_equip_selected.bind(slot)
			)


func _add_action_button(text: String, callback: Callable) -> void:
	var button := Button.new()

	button.text = text
	button.pressed.connect(callback)

	_actions.add_child(button)


func _take_selected() -> void:
	if not _selected_item:
		return

	if not is_instance_valid(_viewer):
		return

	if not is_instance_valid(_owner):
		return

	var world := GameWorld.find_world(_viewer)

	if not world:
		return

	world.submit_take_item(
		_viewer,
		_owner,
		_selected_item
	)


func _equip_selected(slot: StringName) -> void:
	if not _selected_item:
		return

	if not is_instance_valid(_viewer):
		return

	var world := GameWorld.find_world(_viewer)

	if not world:
		return

	world.submit_equip_item(
		_viewer,
		_selected_item,
		slot
	)


func _unequip_slot(slot: StringName) -> void:
	if not is_instance_valid(_viewer):
		return

	var world := GameWorld.find_world(_viewer)

	if not world:
		return

	world.submit_unequip_item(
		_viewer,
		slot
	)

func _drop_selected() -> void:
	if not _selected_item:
		return

	if not is_instance_valid(_viewer):
		return

	var world := GameWorld.find_world(
		_viewer
	)

	if not world:
		return

	world.submit_drop_item(
		_viewer,
		_selected_item
	)

func _consume_selected() -> void:
	if not _selected_item:
		return

	if not is_instance_valid(_viewer):
		return

	var world := GameWorld.find_world(
		_viewer
	)

	if not world:
		return

	world.submit_consume_item(
		_viewer,
		_selected_item
	)

func _choose_selected() -> void:
	if not _selected_item:
		return

	var chosen_item := _selected_item

	_selection_mode = false
	close_inventory()

	item_chosen.emit(chosen_item)

func _on_close_pressed() -> void:
	var was_selecting := _selection_mode

	close_inventory()

	if was_selecting:
		item_selection_cancelled.emit()

func is_selecting_item() -> bool:
	return _selection_mode
