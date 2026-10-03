extends RefCounted
class_name RuntimeID

##Creates a psuedo-unique hash for use as a UUID.
##Chances of a duplicate are like one in quintillions and
##it's easy to reroll, so it's not an issue at all
static func generate() -> String:
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(16)

	return bytes.hex_encode()
