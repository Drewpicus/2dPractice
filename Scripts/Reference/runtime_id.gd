extends RefCounted
class_name RuntimeID


static func generate() -> String:
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(16)

	return bytes.hex_encode()
