extends RefCounted
class_name ParameterCoercion


static func coerce_for_property(target: Object, property_name: StringName, value: Variant) -> Variant:
	var current_value = target.get(property_name)

	if current_value is Array and value is Array:
		var current_array := current_value as Array

		if current_array.is_typed():
			return Array(
				value,
				current_array.get_typed_builtin(),
				current_array.get_typed_class_name(),
				current_array.get_typed_script()
			)

	return _coerce_scalar(current_value, value)


static func _coerce_scalar(current_value: Variant, value: Variant) -> Variant:
	var expected_type := typeof(current_value)

	match expected_type:
		TYPE_STRING_NAME:
			return StringName(value)

		TYPE_STRING:
			return String(value)

		TYPE_INT:
			if value is int or value is float:
				return int(value)

		TYPE_FLOAT:
			if value is int or value is float:
				return float(value)

		TYPE_BOOL:
			if value is bool:
				return value

	return value
