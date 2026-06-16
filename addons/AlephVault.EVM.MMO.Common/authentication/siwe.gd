extends Object

const METHOD := "siwe"
const VERSION := 1
const NONCE_HEX_LENGTH := 66
const ADDRESS_HEX_LENGTH := 42
const EIP712_DOMAIN_NAME := "AlephVault EVM MMO Login"
const EIP712_DOMAIN_VERSION := "1"
const PRIMARY_TYPE := "AlephVaultEvmMmoLogin"

static func normalize_address(address: String) -> String:
	var value := address.strip_edges()
	if not value.begins_with("0x") or value.length() != ADDRESS_HEX_LENGTH:
		return ""
	for i in range(2, value.length()):
		if not _is_hex_char(value.substr(i, 1)):
			return ""
	return value.to_lower()

static func is_valid_address(address: String) -> bool:
	var normalized := normalize_address(address)
	if normalized.is_empty():
		return false
	return normalized.substr(2) != "0000000000000000000000000000000000000000"

static func is_valid_nonce(nonce: String) -> bool:
	var value := nonce.strip_edges()
	if not value.begins_with("0x") or value.length() != NONCE_HEX_LENGTH:
		return false
	for i in range(2, value.length()):
		if not _is_hex_char(value.substr(i, 1)):
			return false
	return true

static func generate_nonce() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bytes := PackedByteArray()
	for i in range(32):
		bytes.push_back(rng.randi_range(0, 255))
	return "0x" + bytes.hex_encode()

static func make_payload(
	domain: String,
	address: String,
	chain_id: int,
	expiration_time: int,
	nonce: String = ""
) -> Dictionary:
	if nonce.is_empty():
		nonce = generate_nonce()
	return {
		"domain": domain,
		"address": address,
		"chainId": chain_id,
		"nonce": nonce,
		"version": VERSION,
		"expirationTime": expiration_time,
	}

static func make_typed_data(payload: Dictionary) -> Dictionary:
	return {
		"types": {
			"EIP712Domain": [
				{"name": "name", "type": "string"},
				{"name": "version", "type": "string"},
			],
			PRIMARY_TYPE: [
				{"name": "address", "type": "address"},
				{"name": "chainId", "type": "uint32"},
				{"name": "domain", "type": "string"},
				{"name": "nonce", "type": "bytes32"},
				{"name": "version", "type": "uint32"},
				{"name": "expirationTime", "type": "uint64"},
			],
		},
		"primaryType": PRIMARY_TYPE,
		"domain": {
			"name": EIP712_DOMAIN_NAME,
			"version": EIP712_DOMAIN_VERSION,
		},
		"message": {
			"address": str(payload["address"]),
			"chainId": int(payload["chainId"]),
			"domain": str(payload["domain"]),
			"nonce": str(payload["nonce"]),
			"version": int(payload["version"]),
			"expirationTime": int(payload["expirationTime"]),
		},
	}

static func make_typed_data_json(payload: Dictionary) -> String:
	return JSON.stringify(make_typed_data(payload))

static func reject(reason: String, extra: Dictionary = {}) -> Dictionary:
	var failed := {"reason": reason}
	for key in extra.keys():
		failed[key] = extra[key]
	return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject(failed)

static func _is_hex_char(value: String) -> bool:
	return "0123456789abcdefABCDEF".contains(value)
